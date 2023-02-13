defmodule Exonerate.Type.Null do
  @moduledoc false

  alias Exonerate.Combining
  alias Exonerate.Tools

  @filters Combining.filters()

  def filter(schema, name, pointer) do
    filters = filter_calls(schema, name, pointer)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_integer(content) do
        unquote(filters)
      end
    end
  end

  defp filter_calls(schema, name, pointer) do
    case Map.take(schema, @filters) do
      empty when empty === %{} ->
        :ok

      filters ->
        build_filters(filters, name, pointer)
    end
  end

  defp build_filters(filters, name, pointer) do
    filter_clauses =
      Enum.map(filters, fn {filter, _} ->
        call =
          pointer
          |> JsonPointer.traverse(filter)
          |> Tools.pointer_to_fun_name(authority: name)

        quote do
          :ok <- unquote(call)(content, path)
        end
      end)

    quote do
      with unquote_splicing(filter_clauses) do
        :ok
      end
    end
  end

  def accessories(_, _, _, _), do: []
end
