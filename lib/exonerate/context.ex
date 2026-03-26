defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"
  #
  # Naming conventions:
  # - `local_schema` = the JSON schema content at current pointer (a map)
  # - `ctx` = CompilationContext struct (used internally)
  # - `opts` = keyword list (only at macro boundaries in quote blocks)

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.CompilationContext
  alias Exonerate.Declaration
  alias Exonerate.Degeneracy
  alias Exonerate.Tools
  alias Exonerate.Type

  @doc """
  scrubs an options keyword prior to entry into a non-combining context.  The following
  keywords should be scrubbed:

  - :only
  - :tracked
  - :seen
  """
  defdelegate scrub_opts(opts), to: CompilationContext

  defmacro filter(resource, pointer, opts) do
    caller = __CALLER__
    ctx = CompilationContext.from_opts(opts)
    call = Tools.call(resource, pointer, ctx)

    if Cache.register_context(caller.module, call) do
      local_schema = Tools.subschema(caller, resource, pointer)

      # Phase 1: Register declaration with degeneracy info
      decl =
        Declaration.new(resource, pointer, ctx)
        |> Declaration.with_degeneracy(Degeneracy.class(local_schema))

      Cache.register_declaration(caller.module, decl)

      # Phase 2: Generate code
      local_schema
      |> build_filter(resource, pointer, ctx)
      |> Tools.maybe_dump(caller, ctx)
    else
      []
    end
  end

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()
  @seen_filters @combining_filters -- ["not"]

  # Object tracking needs extended modules that include dependentSchemas
  @object_combining_modules Map.put(
                              @combining_modules,
                              "dependentSchemas",
                              Exonerate.Filter.DependentSchemas
                            )

  # Object tracking detection - mirrors Type.Object.needs_seen?
  @object_seen_filters ~w(allOf anyOf if oneOf dependentSchemas $ref)
  defp needs_object_tracking?(local_schema) do
    is_map_key(local_schema, "unevaluatedProperties") and
      Enum.any?(@object_seen_filters, &is_map_key(local_schema, &1))
  end

  # Array tracking detection - mirrors Type.Array.needs_combining_seen?
  @array_seen_filters ~w(allOf anyOf if oneOf $ref)
  defp needs_array_tracking?(local_schema) do
    is_map_key(local_schema, "unevaluatedItems") and
      Enum.any?(@array_seen_filters, &is_map_key(local_schema, &1))
  end

  defp build_filter(true, resource, pointer, ctx) do
    call = Tools.call(resource, pointer, ctx)

    result =
      case ctx.tracked do
        :object ->
          quote do
            {:ok, MapSet.new()}
          end

        :array ->
          {:ok, 0}

        nil ->
          :ok
      end

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, _path) do
        unquote(result)
      end
    end
  end

  defp build_filter(false, resource, pointer, ctx) do
    call = Tools.call(resource, pointer, ctx)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(resource), unquote(pointer), path)
      end
    end
  end

  # metadata
  defp build_filter(local_schema = %{"title" => _}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("title")
    |> build_filter(resource, pointer, ctx)
  end

  defp build_filter(local_schema = %{"description" => _}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("description")
    |> build_filter(resource, pointer, ctx)
  end

  defp build_filter(local_schema = %{"examples" => _}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("examples")
    |> build_filter(resource, pointer, ctx)
  end

  defp build_filter(local_schema = %{"default" => _}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("default")
    |> build_filter(resource, pointer, ctx)
  end

  # ID-swapping
  defp build_filter(local_schema = %{"id" => id}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("id")
    |> id_swap_with(id, resource, pointer, ctx)
  end

  defp build_filter(local_schema = %{"$id" => id}, resource, pointer, ctx) do
    local_schema
    |> Map.delete("$id")
    |> id_swap_with(id, resource, pointer, ctx)
  end

  # intercept consts
  defp build_filter(local_schema = %{"const" => const}, resource, pointer, ctx) do
    const_pointer = JsonPtr.join(pointer, "const")

    rest_filter =
      local_schema
      |> Map.delete("const")
      |> build_filter(resource, pointer, CompilationContext.merge(ctx, type: Type.of(const)))

    const = Macro.escape(const)

    quote do
      defp unquote(Tools.call(resource, pointer, ctx))(content, path)
           when content != unquote(const) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(resource), unquote(const_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  # intercept enums
  defp build_filter(local_schema = %{"enum" => enum}, resource, pointer, ctx) do
    enum_pointer = JsonPtr.join(pointer, "enum")

    types =
      enum
      |> Enum.flat_map(&List.wrap(Type.of(&1)))
      |> Enum.uniq()

    rest_filter =
      local_schema
      |> Map.delete("enum")
      |> build_filter(resource, pointer, CompilationContext.merge(ctx, type: types))

    values = Macro.escape(enum)

    quote do
      defp unquote(Tools.call(resource, pointer, ctx))(content, path)
           when content not in unquote(values) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(resource), unquote(enum_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  @all_types Type.all()

  # NB: local_schema should always contain a type field as per Degeneracy.canonicalize/2 called from Tools.subschema/3
  defp build_filter(local_schema = %{"type" => types}, resource, pointer, ctx) do
    # condition the bindings
    filtered_types =
      ctx
      |> CompilationContext.get_only(@all_types)
      |> MapSet.new()

    # Convert to opts for macro boundaries
    opts = CompilationContext.to_opts(ctx)

    {filters, accessories} =
      types
      |> List.wrap()
      |> MapSet.new()
      |> MapSet.intersection(filtered_types)
      |> Enum.map(fn type ->
        module = Type.module(type)

        {quote do
           require unquote(module)
           unquote(module).filter(unquote(resource), unquote(pointer), unquote(opts))
         end,
         quote do
           unquote(module).accessories(unquote(resource), unquote(pointer), unquote(opts))
         end}
      end)
      |> Enum.unzip()

    # Pass type constraint to combining schemas to avoid Dialyzer warnings
    # See: https://github.com/E-xyza/Exonerate/issues/85
    # Intersect with existing :only constraint to accumulate type restrictions
    current_types = types |> List.wrap() |> MapSet.new()
    combining_ctx = CompilationContext.constrain_types(ctx, MapSet.to_list(current_types))
    combining_opts = CompilationContext.to_opts(combining_ctx)

    # Check if we need to generate tracked versions of combining filters
    needs_object_tracking = needs_object_tracking?(local_schema)
    needs_array_tracking = needs_array_tracking?(local_schema)

    # Generate untracked combining filters (standard behavior)
    combining =
      for filter <- @seen_filters, is_map_key(local_schema, filter) do
        combining_module = Map.fetch!(@combining_modules, filter)
        combining_pointer = JsonPtr.join(pointer, filter)

        quote do
          require unquote(combining_module)

          unquote(combining_module).filter(
            unquote(resource),
            unquote(combining_pointer),
            unquote(combining_opts)
          )
        end
      end ++
        List.wrap(
          if is_map_key(local_schema, "not") do
            not_ctx = CompilationContext.with_tracked(combining_ctx, nil)
            not_opts = CompilationContext.to_opts(not_ctx)

            quote do
              require Exonerate.Combining.Not

              Exonerate.Combining.Not.filter(
                unquote(resource),
                unquote(JsonPtr.join(pointer, "not")),
                unquote(not_opts)
              )
            end
          end
        )

    # Generate tracked object combining filters when unevaluatedProperties is present
    # This centralizes the tracked filter generation that was previously in Type.Object.tracked_accessories
    tracked_object_combining =
      if needs_object_tracking do
        # For object tracking, we constrain :only to "object" and set :tracked to :object
        tracked_object_ctx =
          combining_ctx
          |> CompilationContext.with_tracked(:object)
          |> CompilationContext.constrain_types(["object"])

        tracked_object_opts = CompilationContext.to_opts(tracked_object_ctx)

        for filter <- @object_seen_filters, is_map_key(local_schema, filter) do
          combining_module = Map.fetch!(@object_combining_modules, filter)
          combining_pointer = JsonPtr.join(pointer, filter)

          quote do
            require unquote(combining_module)

            unquote(combining_module).filter(
              unquote(resource),
              unquote(combining_pointer),
              unquote(tracked_object_opts)
            )
          end
        end
      else
        []
      end

    # Generate tracked array combining filters when unevaluatedItems is present
    # This centralizes the tracked filter generation that was previously in Type.Array.build_tracked_filters
    tracked_array_combining =
      if needs_array_tracking do
        # For array tracking, we constrain :only to "array" and set :tracked to :array
        tracked_array_ctx =
          combining_ctx
          |> CompilationContext.with_tracked(:array)
          |> CompilationContext.constrain_types(["array"])

        tracked_array_opts = CompilationContext.to_opts(tracked_array_ctx)

        for filter <- @array_seen_filters, is_map_key(local_schema, filter) do
          combining_module = Map.fetch!(@combining_modules, filter)
          combining_pointer = JsonPtr.join(pointer, filter)

          quote do
            require unquote(combining_module)

            unquote(combining_module).filter(
              unquote(resource),
              unquote(combining_pointer),
              unquote(tracked_array_opts)
            )
          end
        end
      else
        []
      end

    quote do
      unquote(filters)
      Exonerate.Context.fallthrough(unquote(resource), unquote(pointer), unquote(opts))
      unquote(combining)
      unquote(tracked_object_combining)
      unquote(tracked_array_combining)
      unquote(accessories)
    end
  end

  # fallthrough still receives opts from quote blocks (macro boundary)
  defmacro fallthrough(resource, pointer, opts) do
    type_failure_pointer = JsonPtr.join(pointer, "type")
    ctx = CompilationContext.from_opts(opts)

    Tools.maybe_dump(
      quote do
        defp unquote(Tools.call(resource, pointer, ctx))(content, path) do
          require Exonerate.Tools

          Exonerate.Tools.mismatch(
            content,
            unquote(resource),
            unquote(type_failure_pointer),
            path
          )
        end
      end,
      __CALLER__,
      ctx
    )
  end

  defp id_swap_with(local_schema, id, resource, pointer, ctx) do
    this_call = Tools.call(resource, pointer, ctx)

    updated_resource =
      id
      |> update_resource_uri(resource)
      |> Tools.uri_to_resource()

    updated_pointer = JsonPtr.from_path("/")

    updated_call = Tools.call(updated_resource, updated_pointer, ctx)

    rest = build_filter(local_schema, updated_resource, updated_pointer, ctx)

    if updated_call === this_call do
      rest
    else
      quote do
        defp unquote(this_call)(content, path) do
          unquote(updated_call)(content, path)
        end

        unquote(rest)
      end
    end
  end

  defp update_resource_uri(id, current_resource) do
    case URI.parse(id) do
      %{fragment: fragment} when not is_nil(fragment) ->
        raise ArgumentError, "id cannot contain a fragment (contained #{id})"

      non_fragment_uri ->
        "#{current_resource}"
        |> URI.parse()
        |> Tools.uri_merge(non_fragment_uri)
    end
  end
end
