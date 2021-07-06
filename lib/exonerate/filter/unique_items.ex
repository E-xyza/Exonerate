defmodule Exonerate.Filter.UniqueItems do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(true, validation) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
    |> put_in([:accumulator, :unique], MapSet.new())
  end
  def append_filter(false, validation), do: validation

  defp name(validation) do
    Exonerate.path_to_call(["uniqueItems" | validation.path])
  end

  defp code(validation) do
    [quote do
       defp unquote(name(validation))({item, index}, acc, path) do
         if item in acc.unique, do: Exonerate.mismatch(item, Path.join(path, to_string(index)))
         Map.put(acc, :unique, MapSet.put(acc.unique, item))
       end
     end]
  end
end
