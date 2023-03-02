defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Type.Object

  defmacro from_cached(name, pointer, opts) do
    module = __CALLER__.module

    if Cache.register_context(module, name, pointer, 2) do
      module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)
      |> to_quoted_function(module, name, pointer, opts)
      |> Tools.maybe_dump(opts)
    else
      []
    end
  end

  @filter_map %{
    "array" => Exonerate.Type.Array,
    "boolean" => Exonerate.Type.Boolean,
    "integer" => Exonerate.Type.Integer,
    "null" => Exonerate.Type.Null,
    "number" => Exonerate.Type.Number,
    "object" => Exonerate.Type.Object,
    "string" => Exonerate.Type.String
  }

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  defp to_quoted_function(true, _module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, _path) do
        require Exonerate.Combining
        Exonerate.Combining.initialize(unquote(opts[:tracked]))
      end
    end
  end

  defp to_quoted_function(false, _module, name, pointer, _opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
      end
    end
  end

  defp to_quoted_function(subschema = %{"id" => id}, module, name, pointer, opts) do
    subschema
    |> Map.delete("id")
    |> to_quoted_function(module, name, pointer, Keyword.put(opts, :id, id))
  end

  defp to_quoted_function(subschema = %{"$ref" => ref_pointer}, module, name, pointer, opts) do
    degeneracy =
      case ref_pointer do
        "#/" <> uri ->
          Tools.degeneracy(module, name, JsonPointer.from_uri("/" <> uri))

        _ ->
          :unknown
      end

    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") or degeneracy === :error do
      call = Tools.pointer_to_fun_name(pointer, authority: name)
      ref_pointer = JsonPointer.join(pointer, "$ref")
      ref_call = Tools.pointer_to_fun_name(ref_pointer, authority: name)

      quote do
        @compile {:inline, [{unquote(call), 2}]}
        defp unquote(call)(content, path) do
          unquote(ref_call)(content, path)
        end

        require Exonerate.Combining.Ref

        Exonerate.Combining.Ref.filter_from_cached(
          unquote(name),
          unquote(ref_pointer),
          unquote(opts)
        )
      end
    else
      subschema
      |> Map.delete("$ref")
      |> to_quoted_function(module, name, pointer, opts)
    end
  end

  # metadata
  defp to_quoted_function(schema = %{"title" => title}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    rest =
      schema
      |> Map.delete("title")
      |> to_quoted_function(module, name, pointer, opts)

    quote do
      defp unquote(call)(:title, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp to_quoted_function(schema = %{"description" => title}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    rest =
      schema
      |> Map.delete("description")
      |> to_quoted_function(module, name, pointer, opts)

    quote do
      defp unquote(call)(:description, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp to_quoted_function(schema = %{"examples" => title}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    rest =
      schema
      |> Map.delete("examples")
      |> to_quoted_function(module, name, pointer, opts)

    quote do
      defp unquote(call)(:examples, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp to_quoted_function(schema = %{"default" => title}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    rest =
      schema
      |> Map.delete("default")
      |> to_quoted_function(module, name, pointer, opts)

    quote do
      defp unquote(call)(:default, _), do: unquote(title)

      unquote(rest)
    end
  end

  # intercept consts
  defp to_quoted_function(schema = %{"const" => const}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    const_pointer =
      pointer
      |> JsonPointer.join("const")
      |> JsonPointer.to_uri()

    rest_filter =
      schema
      |> Map.delete("const")
      |> to_quoted_function(module, name, pointer, Keyword.merge(opts, type: typeof(const)))

    value = Macro.escape(const)

    quote do
      defp unquote(call)(content, path) when content != unquote(value) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(const_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  # intercept enums
  defp to_quoted_function(schema = %{"enum" => enum}, module, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    enum_pointer =
      pointer
      |> JsonPointer.join("enum")
      |> JsonPointer.to_uri()

    types =
      enum
      |> Enum.flat_map(&List.wrap(typeof(&1)))
      |> Enum.uniq()

    rest_filter =
      schema
      |> Map.delete("enum")
      |> to_quoted_function(module, name, pointer, Keyword.merge(opts, type: types))

    values = Macro.escape(enum)

    quote do
      defp unquote(call)(content, path) when content not in unquote(values) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(enum_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  defp to_quoted_function(%{"type" => type_or_types}, module, name, pointer, opts) do
    # condition the bindings
    call =
      pointer
      |> Tools.if(
        opts[:track_items] || opts[:track_properties],
        &JsonPointer.join(&1, ":tracked")
      )
      |> Tools.pointer_to_fun_name(authority: name)

    subschema = module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)

    subschema = Object.remove_degenerate_features(subschema)

    types = resolve_types(type_or_types)

    type_filters = Enum.map(types, &Type.module(&1).filter(subschema, name, pointer, opts))

    accessories =
      Enum.flat_map(types, &Type.module(&1).accessories(subschema, name, pointer, opts))

    combiners =
      @combining_filters
      |> Enum.flat_map(fn
        combiner ->
          List.wrap(
            if is_map_key(subschema, combiner) do
              module = @combining_modules[combiner]
              pointer = JsonPointer.join(pointer, combiner)

              quote do
                require unquote(module)
                unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
              end
            end
          )
      end)

    schema_pointer =
      pointer
      |> JsonPointer.join("type")
      |> JsonPointer.to_uri()

    case Tools.degeneracy(subschema) do
      :ok ->
        quote do
          defp unquote(call)(content, path), do: :ok
        end

      _ ->
        quote do
          unquote(type_filters)

          defp unquote(call)(content, path) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
          end

          unquote(combiners)

          unquote(accessories)
        end
    end
  end

  @all_types ~w(string object array number integer boolean null)

  defp to_quoted_function(schema, module, name, pointer, opts) when is_map(schema) do
    # if it doesn't have a type, inject the type here.

    schema_types =
      schema
      |> Map.get("type", @all_types)
      |> List.wrap()
      |> MapSet.new()

    type =
      opts
      |> Keyword.get(:type, @all_types)
      |> List.wrap()
      |> MapSet.new()
      |> MapSet.intersection(schema_types)
      |> Enum.to_list()

    schema
    |> Map.put("type", type)
    |> to_quoted_function(module, name, pointer, Keyword.drop(opts, [:type]))
  end

  defp typeof(value) when is_binary(value), do: "string"
  defp typeof(value) when is_map(value), do: "object"
  defp typeof(value) when is_list(value), do: "array"
  defp typeof(value) when is_integer(value), do: ["integer", "number"]
  defp typeof(value) when is_float(value), do: "number"
  defp typeof(value) when is_boolean(value), do: "boolean"
  defp typeof(value) when is_nil(value), do: "null"

  defp resolve_types(type) do
    # make sure that "number" implements integer, always
    type
    |> List.wrap()
    |> Enum.flat_map(fn
      "number" -> ["number", "integer"]
      other -> List.wrap(other)
    end)
    |> Enum.uniq()
  end
end
