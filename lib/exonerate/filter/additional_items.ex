defmodule Exonerate.Filter.AdditionalItems do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["additionalItems" | validation.path])
  end

  defp code(schema, validation) do
    [quote do
       defp unquote(name(validation))({item, index}, acc = %{tuple_size: size}, path) when index >= size do
         unquote(name(validation))(item, Path.join(path, to_string(index)))
         acc
       end
       defp unquote(name(validation))(_, acc, _), do: acc
     end,
     Exonerate.Validation.from_schema(schema, ["additionalItems" | validation.path])]
  end
end
