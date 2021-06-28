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
     end]
  end

  defmacro postprocess(nil, _, _, _), do: :ok
  defmacro postprocess(_, acc, list, path) do
    quote do
      unless unquote(acc).min, do: Exonerate.mismatch(unquote(list), unquote(path), guard: "minItems")
    end
  end
end
