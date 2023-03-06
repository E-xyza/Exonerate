defmodule Exonerate.Type.String do
  @moduledoc false

  @behaviour Exonerate.Type

  # alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Combining

  @modules Combining.merge(%{
             "minLength" => Exonerate.Filter.MinLength,
             "maxLength" => Exonerate.Filter.MaxLength,
             "min-max-length" => Exonerate.Filter.MinMaxLength,
             "pattern" => Exonerate.Filter.Pattern
           })

  @filters Map.keys(@modules)

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(schema = %{"format" => "binary"}, authority, pointer, opts) do
    filters = build_filter_with_clause(schema, authority, pointer, opts)

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(content, path) when is_binary(content) do
        unquote(filters)
      end
    end
  end

  defp build_filter(schema, authority, pointer, opts) do
    filters = build_filter_with_clause(schema, authority, pointer, opts)
    non_utf_error_pointer = JsonPointer.join(pointer, "type")

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(string, path) when is_binary(string) do
        if String.valid?(string) do
          unquote(filters)
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(string, unquote(non_utf_error_pointer), path)
        end
      end
    end
  end

  defp build_filter_with_clause(schema, authority, pointer, opts) do
    filter_clauses =
      for filter <- @filters, is_map_key(schema, filter) do
        call = Tools.call(authority, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

        quote do
          :ok <- unquote(call)(string, path)
        end
      end

    quote do
      with unquote_splicing(filter_clauses) do
        :ok
      end
    end
  end

  defmacro accessories(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_accessories(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, authority, pointer, opts) do
    for filter <- @filters, is_map_key(context, filter), not Combining.filter?(filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(authority), unquote(pointer), unquote(opts))
      end
    end
  end
end
