defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Degeneracy
  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Type.Object

  defmacro filter(authority, pointer, opts) do
    caller = __CALLER__
    call = Tools.call(authority, pointer, opts)

    if Cache.register_context(caller.module, call) do
      __CALLER__
      |> Tools.subschema(authority, pointer, true)
      |> build_code(authority, pointer, opts)
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

  defp build_code(true, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, _path) do
        require Exonerate.Combining
        Exonerate.Combining.initialize(unquote(opts[:track_properties]))
      end
    end
  end

  defp build_code(false, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(pointer), path)
      end
    end
  end

  defp build_code(subschema = %{"id" => id}, authority, pointer, opts) do
    subschema
    |> Map.delete("id")
    |> build_code(authority, pointer, Keyword.put(opts, :id, id))
  end

  defp build_code(subschema = %{"$ref" => _}, authority, pointer, opts) do
    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") do
      call = Tools.call(authority, pointer, opts)
      ref_pointer = JsonPointer.join(pointer, "$ref")
      ref_call = Tools.call(authority, ref_pointer, opts)

      quote do
        @compile {:inline, [{unquote(call), 2}]}
        defp unquote(call)(content, path) do
          unquote(ref_call)(content, path)
        end

        require Exonerate.Combining.Ref

        Exonerate.Combining.Ref.filter(
          unquote(authority),
          unquote(ref_pointer),
          unquote(opts)
        )
      end
    else
      subschema
      |> Map.delete("$ref")
      |> build_code(authority, pointer, opts)
    end
  end

  # metadata
  defp build_code(schema = %{"title" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("title")
      |> build_code(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:title, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_code(schema = %{"description" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("description")
      |> build_code(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:description, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_code(schema = %{"examples" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("examples")
      |> build_code(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:examples, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_code(schema = %{"default" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("default")
      |> build_code(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:default, _), do: unquote(title)

      unquote(rest)
    end
  end

  # intercept consts
  defp build_code(schema = %{"const" => const}, authority, pointer, opts) do
    const_pointer = JsonPointer.join(pointer, "const")

    rest_filter =
      schema
      |> Map.delete("const")
      |> build_code(authority, pointer, Keyword.merge(opts, type: Type.of(const)))

    value = Macro.escape(const)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(content, path)
           when content != unquote(value) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(const_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  # intercept enums
  defp build_code(schema = %{"enum" => enum}, authority, pointer, opts) do
    enum_pointer = JsonPointer.join(pointer, "enum")

    types =
      enum
      |> Enum.flat_map(&List.wrap(Type.of(&1)))
      |> Enum.uniq()

    rest_filter =
      schema
      |> Map.delete("enum")
      |> build_code(authority, pointer, Keyword.merge(opts, type: types))

    values = Macro.escape(enum)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(content, path)
           when content not in unquote(values) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(enum_pointer), path)
      end

      unquote(rest_filter)
    end
  end

  # NB: schema should always contain a type field as per Degeneracy.canonicalize/1 called from Tools.subschema/3
  defp build_code(subschema = %{"type" => types}, authority, pointer, opts) do
    # condition the bindings
    call = Tools.call(authority, pointer, opts)

    case Degeneracy.class(subschema) do
      :ok ->
        quote do
          defp unquote(call)(content, _path) do
            require Exonerate.Combining
            Exonerate.Combining.initialize(unquote(opts[:track_properties]))
          end
        end

      _ ->
        {filters, accessories} =
          types
          |> MapSet.new()
          |> MapSet.intersection(MapSet.new(List.wrap(opts[:only])))
          |> Enum.map(fn type ->
            module = Type.module(type)

            {quote do
               require unquote(module)
               unquote(module).filter(unquote(authority), unquote(pointer), unquote(opts))
             end,
             quote do
               unquote(module).accessory(unquote(authority), unquote(pointer), unquote(opts))
             end}
          end)
          |> Enum.unzip()

        type_failure_pointer = JsonPointer.join(pointer, "type")

        quote do
          unquote(filters)

          defp unquote(call)(content, path) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(type_failure_pointer), path)
          end

          unquote(accessories)
        end
    end
  end
end
