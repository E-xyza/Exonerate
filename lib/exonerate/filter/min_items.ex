defmodule Exonerate.Filter.MinItems do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(minimum, validation) when is_integer(minimum) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(minimum, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
    |> put_in([:accumulator, :min], false)
    |> put_in([:post_accumulate], [name(validation) | validation.post_accumulate])
  end

  defp name(validation) do
    Exonerate.path(["minItems" | validation.path])
  end

  defp code(minimum, validation) do
    [quote do
       defp unquote(name(validation))({_, index}, acc, path) do
         if (not acc.min) or index >= unquote(minimum) - 1 do
           %{acc | min: true}
         else
           acc
         end
       end
       defp unquote(name(validation))(acc = %{min: satisfied}, list, path) do
         unless satisfied, do: Exonerate.mismatch(list, path)
       end
       defp unquote(name(validation))(_, _, _), do: :ok
     end]
  end
end
