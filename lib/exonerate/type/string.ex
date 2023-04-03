defmodule Exonerate.Type.String do
  @moduledoc false

  @behaviour Exonerate.Type

  # alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Combining
  alias Exonerate.Filter.Format

  @modules Combining.merge(%{
             "minLength" => Exonerate.Filter.MinLength,
             "maxLength" => Exonerate.Filter.MaxLength,
             "min-max-length" => Exonerate.Filter.MinMaxLength,
             "format" => Exonerate.Filter.Format,
             "pattern" => Exonerate.Filter.Pattern
           })

  @filters Map.keys(@modules)

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(schema = %{"format" => "binary"}, resource, pointer, opts) do
    filters = build_filter_with_clause(schema, resource, pointer, opts)

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) when is_binary(string) do
        unquote(filters)
      end
    end
  end

  defp build_filter(schema, resource, pointer, opts) do
    filters = build_filter_with_clause(schema, resource, pointer, opts)
    non_utf_error_pointer = JsonPointer.join(pointer, "type")

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) when is_binary(string) do
        if String.valid?(string) do
          unquote(filters)
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(string, unquote(non_utf_error_pointer), path)
        end
      end
    end
  end

  defp build_filter_with_clause(schema, resource, pointer, opts) do
    filter_clauses =
      for filter <- @filters,
          is_map_key(schema, filter),
          accept_format?(schema, filter, resource, pointer, opts) do
        call = Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

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

  defp accept_format?(schema, "format", resource, pointer, opts) do
    Format.should_format?(schema["format"], resource, JsonPointer.join(pointer, "format"), opts)
  end

  defp accept_format?(_schema, _, _, _, _), do: true

  defmacro accessories(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_accessories(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, resource, pointer, opts) do
    for filter <- @filters,
        is_map_key(context, filter),
        accept_format?(context, filter, resource, pointer, opts),
        not Combining.filter?(filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end
  end
end
