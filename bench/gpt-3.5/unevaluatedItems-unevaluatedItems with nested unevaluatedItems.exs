defmodule :"unevaluatedItems with nested unevaluatedItems" do
  
defmodule :"unevaluatedItems-unevaluatedItems with nested unevaluatedItems" do
  def validate(object) when is_list(object) do
    case validate_list_items(object, [], []) do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error

  defp validate_list_items([], _, []), do: []
  defp validate_list_items([], _, _), do: :invalid

  defp validate_list_items([item | rest], pref_items, [_ | unevaluated_items]) do
    validate_list_items(rest, pref_items, unevaluated_items)
  end

  defp validate_list_items([item | rest], pref_items, []) do
    case validate_prefix_item(item, pref_items) do
      :ok ->
        validate_list_items(rest, [item | pref_items], [])
      _ ->
        [:invalid | rest]
    end
  end

  defp validate_prefix_item(_item, []) do
    :ok
  end

  defp validate_prefix_item(item, [{type: "string"} | _rest]) when is_binary(item) do
    :ok
  end

  defp validate_prefix_item(item, [{type: "number"} | _rest]) when is_number(item) do
    :ok
  end

  defp validate_prefix_item(_, _), do: :invalid

end

end
