defmodule Exonerate.Filter.PrefixItems do
  @behaviour Exonerate.Filter

  alias Exonerate.Type
  require Type

  # enumerated, tuple validation
  def append_filter(schema, validation) when is_list(schema) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
    |> put_in([:accumulator, :prefix_size], length(schema))
  end

  defp name(validation) do
    Exonerate.path(["prefixItems" | validation.path])
  end
  defp name(validation, index) do
    Exonerate.path([to_string(index), "prefixItems" | validation.path])
  end

  defp code(schema, validation) do
    {calls, funs} = schema
    |> Enum.with_index
    |> Enum.map(fn {item_schema, index} ->
      {
        quote do
          defp unquote(name(validation))({item, unquote(index)}, acc, path) do
            unquote(name(validation, index))(item, Path.join(path, to_string(unquote(index))))
            acc
          end
        end,
        Exonerate.Validation.from_schema(item_schema, [to_string(index), "prefixItems" | validation.path])
      }
    end)
    |> Enum.unzip

    calls ++ [quote do
      defp unquote(name(validation))({item, _}, acc, path), do: acc
    end] ++ funs
  end
end
