defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Degeneracy
  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Type

  defmacro filter(authority, pointer, opts) do
    caller = __CALLER__
    call = Tools.call(authority, pointer, opts)

    if Cache.register_context(caller.module, call) do
      __CALLER__
      |> Tools.subschema(authority, pointer)
      |> build_filter(authority, pointer, opts)
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

  defp build_filter(true, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, _path) do
        require Exonerate.Combining
        Exonerate.Combining.initialize(unquote(opts[:track_properties]))
      end
    end
  end

  defp build_filter(false, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(pointer), path)
      end
    end
  end

  defp build_filter(subschema = %{"id" => id}, authority, pointer, opts) do
    subschema
    |> Map.delete("id")
    |> build_filter(authority, pointer, Keyword.put(opts, :id, id))
  end

  defp build_filter(subschema = %{"$ref" => _}, authority, pointer, opts) do
    if Draft.opts_before?("2019-09", opts) do
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
      |> build_filter(authority, pointer, opts)
    end
  end

  # metadata
  defp build_filter(schema = %{"title" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("title")
      |> build_filter(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:title, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_filter(schema = %{"description" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("description")
      |> build_filter(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:description, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_filter(schema = %{"examples" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("examples")
      |> build_filter(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:examples, _), do: unquote(title)

      unquote(rest)
    end
  end

  defp build_filter(schema = %{"default" => title}, authority, pointer, opts) do
    rest =
      schema
      |> Map.delete("default")
      |> build_filter(authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(:default, _), do: unquote(title)

      unquote(rest)
    end
  end

  # intercept consts
  defp build_filter(schema = %{"const" => const}, authority, pointer, opts) do
    const_pointer = JsonPointer.join(pointer, "const")

    rest_filter =
      schema
      |> Map.delete("const")
      |> build_filter(authority, pointer, Keyword.merge(opts, type: Type.of(const)))

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
  defp build_filter(schema = %{"enum" => enum}, authority, pointer, opts) do
    enum_pointer = JsonPointer.join(pointer, "enum")

    types =
      enum
      |> Enum.flat_map(&List.wrap(Type.of(&1)))
      |> Enum.uniq()

    rest_filter =
      schema
      |> Map.delete("enum")
      |> build_filter(authority, pointer, Keyword.merge(opts, type: types))

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

  @all_types Type.all()

  # NB: schema should always contain a type field as per Degeneracy.canonicalize/1 called from Tools.subschema/3
  defp build_filter(subschema = %{"type" => types}, authority, pointer, opts) do
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
               unquote(module).filter(unquote(authority), unquote(pointer), unquote(opts))
             end,
             quote do
               unquote(module).accessories(unquote(authority), unquote(pointer), unquote(opts))
             end}
          end)
          |> Enum.unzip()

        quote do
          unquote(filters)

          Exonerate.Context.fallthrough(unquote(authority), unquote(pointer), unquote(opts))

          unquote(accessories)
        end
    end
  end

  defmacro fallthrough(authority, pointer, opts) do
    type_failure_pointer = JsonPointer.join(pointer, "type")

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(type_failure_pointer), path)
      end
    end
  end
end
