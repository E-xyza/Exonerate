defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type

  defmacro filter(resource, pointer, opts) do
    caller = __CALLER__
    call = Tools.call(resource, pointer, opts)

    if Cache.register_context(caller.module, call) do
      caller
      |> Tools.subschema(resource, pointer)
      |> build_filter(resource, pointer, opts)
      |> Tools.maybe_dump(opts)
    else
      []
    end
  end

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  defp build_filter(true, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    result =
      case opts[:tracked] do
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

  defp build_filter(false, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(pointer), path)
      end
    end
  end

  # metadata
  defp build_filter(context = %{"title" => _}, resource, pointer, opts) do
    context
    |> Map.delete("title")
    |> build_filter(resource, pointer, opts)
  end

  defp build_filter(context = %{"description" => _}, resource, pointer, opts) do
    context
    |> Map.delete("description")
    |> build_filter(resource, pointer, opts)
  end

  defp build_filter(context = %{"examples" => _}, resource, pointer, opts) do
    context
    |> Map.delete("examples")
    |> build_filter(resource, pointer, opts)
  end

  defp build_filter(context = %{"default" => _}, resource, pointer, opts) do
    context
    |> Map.delete("default")
    |> build_filter(resource, pointer, opts)
  end

  # ID-swapping
  defp build_filter(context = %{"id" => id}, resource, pointer, opts) do
    context
    |> Map.delete("id")
    |> id_swap_with(id, resource, pointer, opts)
  end

  defp build_filter(context = %{"$id" => id}, resource, pointer, opts) do
    context
    |> Map.delete("$id")
    |> id_swap_with(id, resource, pointer, opts)
  end

  # intercept consts
  defp build_filter(context = %{"const" => const}, resource, pointer, opts) do
    const_pointer = JsonPointer.join(pointer, "const")

    rest_filter =
      context
      |> Map.delete("const")
      |> build_filter(resource, pointer, Keyword.merge(opts, type: Type.of(const)))

    const = Macro.escape(const)

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(content, path)
           when content != unquote(const) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(const_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  # intercept enums
  defp build_filter(context = %{"enum" => enum}, resource, pointer, opts) do
    enum_pointer = JsonPointer.join(pointer, "enum")

    types =
      enum
      |> Enum.flat_map(&List.wrap(Type.of(&1)))
      |> Enum.uniq()

    rest_filter =
      context
      |> Map.delete("enum")
      |> build_filter(resource, pointer, Keyword.merge(opts, type: types))

    values = Macro.escape(enum)

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(content, path)
           when content not in unquote(values) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(enum_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  @all_types Type.all()

  # NB: context should always contain a type field as per Degeneracy.canonicalize/2 called from Tools.subschema/3
  defp build_filter(context = %{"type" => types}, resource, pointer, opts) do
    # condition the bindings
    filtered_types =
      opts
      |> Keyword.get(:only, @all_types)
      |> List.wrap()
      |> MapSet.new()

    {filters, accessories} =
      types
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

    # |> Tools.inspect

    combining =
      for filter <- @combining_filters, is_map_key(context, filter) do
        combining_module = @combining_modules[filter]
        combining_pointer = JsonPointer.join(pointer, filter)

        quote do
          require unquote(combining_module)

          unquote(combining_module).filter(
            unquote(resource),
            unquote(combining_pointer),
            unquote(opts)
          )
        end
      end

    quote do
      unquote(filters)
      Exonerate.Context.fallthrough(unquote(resource), unquote(pointer), unquote(opts))
      unquote(combining)
      unquote(accessories)
    end
  end

  defmacro fallthrough(resource, pointer, opts) do
    type_failure_pointer = JsonPointer.join(pointer, "type")

    Tools.maybe_dump(
      quote do
        defp unquote(Tools.call(resource, pointer, opts))(content, path) do
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, unquote(type_failure_pointer), path)
        end
      end,
      opts
    )
  end

  defp id_swap_with(context, id, resource, pointer, opts) do
    this_call = Tools.call(resource, pointer, opts)

    updated_resource =
      id
      |> update_resource_uri(resource)
      |> Tools.uri_to_resource()

    updated_pointer = JsonPointer.from_path("/")

    updated_call = Tools.call(updated_resource, updated_pointer, opts)

    rest = build_filter(context, updated_resource, updated_pointer, opts)

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
