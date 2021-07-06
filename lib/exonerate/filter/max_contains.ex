defmodule Exonerate.Filter.MaxContains do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(maximum, validation) when is_integer(maximum) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(maximum, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path_to_call(["maxContains" | validation.path])
  end

  defp code(maximum, validation) do
    [quote do
       defp unquote(name(validation))({_, index}, acc = %{contains: contains}, path) do
         if contains > unquote(maximum), do: throw {:max, "maxContains"}
         acc
       end
       defp unquote(name(validation))(_, _, _), do: :ok
     end]
  end
end
