defmodule Exonerate.Context do
  @moduledoc """
  Compilation context for JSON Schema validation.

  This module provides both the struct for tracking compilation state and
  the macros for generating validation code.

  ## Struct Fields

  - `:resource` - Current resource URI (String.t())
  - `:pointer` - Current JSON pointer (JsonPtr.t())
  - `:caller` - Caller environment (Macro.Env.t())
  - `:only` - Type constraints for combining schemas ([String.t()] | nil)
  - `:tracked` - Tracking mode for unevaluated properties/items (:object | :array | nil)
  - `:seen` - Seen property tracking (MapSet.t() | nil)
  - `:entrypoint` - Original entrypoint pointer (JsonPtr.t())
  - `:dump` - Debug dump mode (boolean)
  - `:decoders` - Decoder configuration (list)
  - `:content_type` - Content type / MIME type (String.t())
  - `:draft` - JSON Schema draft version (atom)
  - `:format` - Format validation mode (atom | keyword | boolean)

  ## Naming Conventions

  - `local_schema` = the JSON schema content at current pointer (a map)
  - `ctx` = Context struct (used internally)
  - `opts` = keyword list (only at macro boundaries in quote blocks)
  """

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Declaration
  alias Exonerate.Degeneracy
  alias Exonerate.Modules
  alias Exonerate.Tools
  alias Exonerate.Type

  # ============================================================================
  # Struct Definition
  # ============================================================================

  @type t :: %__MODULE__{
          resource: String.t() | nil,
          pointer: JsonPtr.t() | nil,
          caller: Macro.Env.t() | nil,
          only: [String.t()] | nil,
          tracked: :object | :array | nil,
          seen: MapSet.t() | nil,
          entrypoint: JsonPtr.t() | nil,
          dump: boolean | nil,
          decoders: list | nil,
          content_type: String.t() | nil,
          draft: atom | nil,
          format: atom | keyword | boolean | nil,
          decimal: :all | keyword | nil
        }

  defstruct [
    :resource,
    :pointer,
    :caller,
    :only,
    :tracked,
    :seen,
    :entrypoint,
    :dump,
    :decoders,
    :content_type,
    :draft,
    :format,
    :decimal
  ]

  # ============================================================================
  # Struct Functions
  # ============================================================================

  @doc """
  Creates a new Context from keyword options.
  """
  @spec from_opts(keyword) :: t()
  def from_opts(opts) when is_list(opts) do
    %__MODULE__{
      resource: Keyword.get(opts, :resource),
      pointer: Keyword.get(opts, :pointer),
      caller: Keyword.get(opts, :caller),
      only: normalize_only(Keyword.get(opts, :only)),
      tracked: Keyword.get(opts, :tracked),
      seen: Keyword.get(opts, :seen),
      entrypoint: Keyword.get(opts, :entrypoint),
      dump: Keyword.get(opts, :dump),
      decoders: Keyword.get(opts, :decoders),
      content_type: Keyword.get(opts, :content_type),
      draft: Keyword.get(opts, :draft),
      format: Keyword.get(opts, :format),
      decimal: Keyword.get(opts, :decimal)
    }
  end

  @doc """
  Converts a Context to keyword options.
  """
  @spec to_opts(t()) :: keyword
  def to_opts(%__MODULE__{} = ctx) do
    ctx
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Keyword.new()
  end

  @doc """
  Merges keyword options into an existing Context.
  """
  @spec merge(t(), keyword) :: t()
  def merge(%__MODULE__{} = ctx, opts) when is_list(opts) do
    opts
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Keyword.update(:only, nil, &normalize_only/1)
    |> then(&struct(ctx, &1))
  end

  @doc """
  Scrubs combining-specific options from the context.

  The following fields are cleared:
  - :only
  - :tracked
  - :seen
  """
  @spec scrub(t()) :: t()
  def scrub(%__MODULE__{} = ctx) do
    %{ctx | only: nil, tracked: nil, seen: nil}
  end

  @doc """
  Scrubs combining-specific options from keyword opts.
  """
  @spec scrub_opts(keyword) :: keyword
  def scrub_opts(opts) when is_list(opts) do
    Keyword.drop(opts, ~w(only tracked seen)a)
  end

  @doc """
  Updates the type constraint (:only) by intersecting with new types.

  This accumulates type restrictions through combining schemas.
  """
  @spec constrain_types(t(), [String.t()] | String.t()) :: t()
  def constrain_types(%__MODULE__{only: nil} = ctx, types) do
    %{ctx | only: List.wrap(types)}
  end

  def constrain_types(%__MODULE__{only: existing} = ctx, types) do
    existing_set = MapSet.new(existing)
    new_set = types |> List.wrap() |> MapSet.new()
    intersection = MapSet.intersection(existing_set, new_set) |> MapSet.to_list()
    %{ctx | only: intersection}
  end

  @doc """
  Sets the tracked mode for the context.
  """
  @spec with_tracked(t(), :object | :array | nil) :: t()
  def with_tracked(%__MODULE__{} = ctx, tracked) do
    %{ctx | tracked: tracked}
  end

  @doc """
  Returns the type constraints as a list, or a default list if not set.
  """
  @spec get_only(t(), [String.t()]) :: [String.t()]
  def get_only(%__MODULE__{only: nil}, default), do: default
  def get_only(%__MODULE__{only: only}, _default), do: only

  # Normalizes :only to always be a list or nil
  defp normalize_only(nil), do: nil
  defp normalize_only(types) when is_list(types), do: types
  defp normalize_only(type) when is_binary(type), do: [type]

  # ============================================================================
  # Module Attributes (shared between Phase 1 and Phase 2)
  # ============================================================================

  @all_types Type.all()
  @combining_modules Combining.modules()
  @combining_filters Combining.filters()
  @seen_filters @combining_filters -- ["not"]

  # Object tracking needs extended modules that include dependentSchemas
  @object_combining_modules Map.put(@combining_modules, "dependentSchemas", Modules.combining("dependentSchemas"))

  # Object/array tracking detection filters
  @object_seen_filters ~w(allOf anyOf if oneOf dependentSchemas $ref)
  @array_seen_filters ~w(allOf anyOf if oneOf $ref)

  defp needs_object_tracking?(local_schema) do
    is_map_key(local_schema, "unevaluatedProperties") and
      Enum.any?(@object_seen_filters, &is_map_key(local_schema, &1))
  end

  defp needs_array_tracking?(local_schema) do
    is_map_key(local_schema, "unevaluatedItems") and
      Enum.any?(@array_seen_filters, &is_map_key(local_schema, &1))
  end

  # ============================================================================
  # Phase 1: Declaration Collection
  # ============================================================================

  @doc """
  Collects all declarations by walking the schema structure.

  This is Phase 1 of the two-phase compilation. It must be called before
  any code generation macros are invoked.
  """
  @spec collect_declarations(module(), String.t(), JsonPtr.t(), keyword()) :: :ok
  def collect_declarations(module, resource, pointer, opts) do
    ctx = from_opts(opts)
    local_schema = Cache.fetch_schema!(module, resource) |> JsonPtr.resolve_json!(pointer)
    do_collect_declarations(module, resource, pointer, ctx, local_schema)
    :ok
  end

  defp do_collect_declarations(module, resource, pointer, ctx, local_schema) do
    call = Tools.call(resource, pointer, ctx)

    # Only process if declaration not already collected
    # Note: We use has_declaration? here, not register_context, because
    # Phase 2's filter macro needs register_context for its own deduplication
    unless Cache.has_declaration?(module, call) do
      # Register the declaration
      decl =
        Declaration.new(resource, pointer, ctx)
        |> Declaration.with_degeneracy(Degeneracy.class(local_schema))

      Cache.register_declaration(module, decl)

      # Recursively collect from nested schemas
      collect_nested_declarations(module, resource, pointer, ctx, local_schema)
    end
  end

  defp collect_nested_declarations(_module, _resource, _pointer, _ctx, local_schema)
       when is_boolean(local_schema),
       do: :ok

  defp collect_nested_declarations(module, resource, pointer, ctx, local_schema)
       when is_map(local_schema) do
    # Get types from schema
    types = Map.get(local_schema, "type", @all_types) |> List.wrap()

    # Collect from type-specific schemas
    collect_type_declarations(module, resource, pointer, ctx, local_schema, types)

    # Collect from combining schemas
    collect_combining_declarations(module, resource, pointer, ctx, local_schema, types)
  end

  defp collect_type_declarations(module, resource, pointer, ctx, local_schema, types) do
    # Object type declarations
    if "object" in types do
      collect_object_declarations(module, resource, pointer, ctx, local_schema)
    end

    # Array type declarations
    if "array" in types do
      collect_array_declarations(module, resource, pointer, ctx, local_schema)
    end
  end

  defp collect_object_declarations(module, resource, pointer, ctx, local_schema) do
    # properties
    if props = local_schema["properties"] do
      for {key, schema} <- props do
        prop_pointer = JsonPtr.join(pointer, ["properties", key])
        do_collect_declarations(module, resource, prop_pointer, scrub(ctx), schema)
      end
    end

    # patternProperties
    if pattern_props = local_schema["patternProperties"] do
      for {pattern, schema} <- pattern_props do
        pp_pointer = JsonPtr.join(pointer, ["patternProperties", pattern])
        do_collect_declarations(module, resource, pp_pointer, scrub(ctx), schema)
      end
    end

    # additionalProperties
    if add_props = local_schema["additionalProperties"] do
      ap_pointer = JsonPtr.join(pointer, "additionalProperties")
      do_collect_declarations(module, resource, ap_pointer, scrub(ctx), add_props)
    end

    # unevaluatedProperties
    if uneval_props = local_schema["unevaluatedProperties"] do
      up_pointer = JsonPtr.join(pointer, "unevaluatedProperties")
      do_collect_declarations(module, resource, up_pointer, scrub(ctx), uneval_props)
    end

    # propertyNames
    if prop_names = local_schema["propertyNames"] do
      pn_pointer = JsonPtr.join(pointer, "propertyNames")
      do_collect_declarations(module, resource, pn_pointer, scrub(ctx), prop_names)
    end

    # dependentSchemas
    if dep_schemas = local_schema["dependentSchemas"] do
      for {key, schema} <- dep_schemas do
        ds_pointer = JsonPtr.join(pointer, ["dependentSchemas", key])
        do_collect_declarations(module, resource, ds_pointer, scrub(ctx), schema)
      end
    end
  end

  defp collect_array_declarations(module, resource, pointer, ctx, local_schema) do
    # items (could be schema or array of schemas in older drafts)
    case local_schema["items"] do
      items when is_map(items) or is_boolean(items) ->
        items_pointer = JsonPtr.join(pointer, "items")
        do_collect_declarations(module, resource, items_pointer, scrub(ctx), items)

      items when is_list(items) ->
        for {schema, index} <- Enum.with_index(items) do
          item_pointer = JsonPtr.join(pointer, ["items", "#{index}"])
          do_collect_declarations(module, resource, item_pointer, scrub(ctx), schema)
        end

      nil ->
        :ok
    end

    # prefixItems
    if prefix_items = local_schema["prefixItems"] do
      for {schema, index} <- Enum.with_index(prefix_items) do
        pi_pointer = JsonPtr.join(pointer, ["prefixItems", "#{index}"])
        do_collect_declarations(module, resource, pi_pointer, scrub(ctx), schema)
      end
    end

    # additionalItems
    if add_items = local_schema["additionalItems"] do
      ai_pointer = JsonPtr.join(pointer, "additionalItems")
      do_collect_declarations(module, resource, ai_pointer, scrub(ctx), add_items)
    end

    # unevaluatedItems
    if uneval_items = local_schema["unevaluatedItems"] do
      ui_pointer = JsonPtr.join(pointer, "unevaluatedItems")
      do_collect_declarations(module, resource, ui_pointer, scrub(ctx), uneval_items)
    end

    # contains
    if contains = local_schema["contains"] do
      c_pointer = JsonPtr.join(pointer, "contains")
      do_collect_declarations(module, resource, c_pointer, scrub(ctx), contains)
    end
  end

  defp collect_combining_declarations(module, resource, pointer, ctx, local_schema, types) do
    # Calculate type constraints for combining schemas
    current_types = MapSet.new(types)
    combining_ctx = constrain_types(ctx, MapSet.to_list(current_types))

    # Collect untracked combining declarations
    for filter <- @combining_filters, schema = local_schema[filter] do
      collect_combining_filter(module, resource, pointer, combining_ctx, filter, schema)
    end

    # Collect tracked object combining declarations if needed
    if needs_object_tracking?(local_schema) do
      tracked_ctx =
        combining_ctx
        |> with_tracked(:object)
        |> constrain_types(["object"])

      for filter <- @combining_filters, filter != "not", schema = local_schema[filter] do
        collect_combining_filter(module, resource, pointer, tracked_ctx, filter, schema)
      end
    end

    # Collect tracked array combining declarations if needed
    if needs_array_tracking?(local_schema) do
      tracked_ctx =
        combining_ctx
        |> with_tracked(:array)
        |> constrain_types(["array"])

      for filter <- @combining_filters, filter != "not", schema = local_schema[filter] do
        collect_combining_filter(module, resource, pointer, tracked_ctx, filter, schema)
      end
    end
  end

  defp collect_combining_filter(module, resource, pointer, ctx, filter, schema) do
    filter_pointer = JsonPtr.join(pointer, filter)

    case filter do
      f when f in ["allOf", "anyOf", "oneOf"] ->
        # Register the combining filter itself
        do_collect_declarations(module, resource, filter_pointer, ctx, true)

        # Collect from each item
        for {item_schema, index} <- Enum.with_index(schema) do
          item_pointer = JsonPtr.join(filter_pointer, "#{index}")
          do_collect_declarations(module, resource, item_pointer, ctx, item_schema)
        end

      "if" ->
        # Register if filter
        do_collect_declarations(module, resource, filter_pointer, ctx, schema)

        # then
        if then_schema = Cache.fetch_schema!(module, resource) |> JsonPtr.resolve_json!(pointer) |> Map.get("then") do
          then_pointer = JsonPtr.join(pointer, "then")
          do_collect_declarations(module, resource, then_pointer, ctx, then_schema)
        end

        # else
        if else_schema = Cache.fetch_schema!(module, resource) |> JsonPtr.resolve_json!(pointer) |> Map.get("else") do
          else_pointer = JsonPtr.join(pointer, "else")
          do_collect_declarations(module, resource, else_pointer, ctx, else_schema)
        end

      "not" ->
        # not filter doesn't track
        not_ctx = with_tracked(ctx, nil)
        do_collect_declarations(module, resource, filter_pointer, not_ctx, schema)

      "$ref" ->
        # Register the ref declaration (the actual resolution happens during code gen)
        do_collect_declarations(module, resource, filter_pointer, ctx, true)

      _ ->
        :ok
    end
  end

  # ============================================================================
  # Phase 2: Code Generation (Filter Macros)
  # ============================================================================

  defmacro filter(resource, pointer, opts) do
    caller = __CALLER__
    ctx = __MODULE__.from_opts(opts)
    call = Tools.call(resource, pointer, ctx)

    if Cache.register_context(caller.module, call) do
      local_schema = Tools.subschema(caller, resource, pointer)

      # Generate code (declarations were already collected in Phase 1)
      local_schema
      |> build_filter(resource, pointer, ctx)
      |> Tools.maybe_dump(caller, ctx)
    else
      []
    end
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
      |> build_filter(resource, pointer, __MODULE__.merge(ctx, type: Type.of(const)))

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
      |> build_filter(resource, pointer, __MODULE__.merge(ctx, type: types))

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

  # NB: local_schema should always contain a type field as per Degeneracy.canonicalize/2 called from Tools.subschema/3
  defp build_filter(local_schema = %{"type" => types}, resource, pointer, ctx) do
    # condition the bindings
    filtered_types =
      ctx
      |> __MODULE__.get_only(@all_types)
      |> MapSet.new()

    # Calculate the type intersection
    schema_types = types |> List.wrap() |> MapSet.new()
    type_intersection = MapSet.intersection(schema_types, filtered_types)

    # Optimization: In tracked mode, if the schema's types don't intersect with the
    # tracked type constraint (:only), skip validation and return empty tracked result.
    # This schema can never match the tracked type, so it won't contribute to seen properties.
    # See: https://github.com/E-xyza/Exonerate/issues/20
    if ctx.tracked && MapSet.size(type_intersection) == 0 do
      build_tracked_passthrough(resource, pointer, ctx)
    else
      build_type_filter(local_schema, resource, pointer, ctx, type_intersection, filtered_types)
    end
  end

  # Generate a passthrough for tracked mode when types don't intersect
  defp build_tracked_passthrough(resource, pointer, ctx) do
    call = Tools.call(resource, pointer, ctx)

    result =
      case ctx.tracked do
        :object ->
          quote do
            {:ok, MapSet.new()}
          end

        :array ->
          {:ok, 0}
      end

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(_content, _path), do: unquote(result)
    end
  end

  defp build_type_filter(local_schema, resource, pointer, ctx, type_intersection, _filtered_types) do
    types = local_schema["type"]

    # Convert to opts for macro boundaries
    opts = __MODULE__.to_opts(ctx)

    {filters, accessories} =
      type_intersection
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
    combining_ctx = __MODULE__.constrain_types(ctx, MapSet.to_list(current_types))
    combining_opts = __MODULE__.to_opts(combining_ctx)

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
            not_ctx = __MODULE__.with_tracked(combining_ctx, nil)
            not_opts = __MODULE__.to_opts(not_ctx)

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
          |> __MODULE__.with_tracked(:object)
          |> __MODULE__.constrain_types(["object"])

        tracked_object_opts = __MODULE__.to_opts(tracked_object_ctx)

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
          |> __MODULE__.with_tracked(:array)
          |> __MODULE__.constrain_types(["array"])

        tracked_array_opts = __MODULE__.to_opts(tracked_array_ctx)

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

    # Get the expected types for error reporting
    expected_types = types |> List.wrap()

    quote do
      unquote(filters)
      Exonerate.Context.fallthrough(unquote(resource), unquote(pointer), unquote(opts), unquote(expected_types))
      unquote(combining)
      unquote(tracked_object_combining)
      unquote(tracked_array_combining)
      unquote(accessories)
    end
  end

  # fallthrough still receives opts from quote blocks (macro boundary)
  defmacro fallthrough(resource, pointer, opts, expected_types) do
    type_failure_pointer = JsonPtr.join(pointer, "type")
    ctx = __MODULE__.from_opts(opts)

    # Format expected types for error message
    expected =
      case expected_types do
        [single] -> single
        multiple -> multiple
      end

    Tools.maybe_dump(
      quote do
        defp unquote(Tools.call(resource, pointer, ctx))(content, path) do
          require Exonerate.Tools

          Exonerate.Tools.mismatch(
            content,
            unquote(resource),
            unquote(type_failure_pointer),
            path,
            expected: unquote(expected)
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
