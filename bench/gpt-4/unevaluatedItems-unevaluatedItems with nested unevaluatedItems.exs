defmodule :"unevaluatedItems-unevaluatedItems with nested unevaluatedItems" do
  def validate(value) when is_list(value) and has_first_item_string(value) and length(value) == 1 do
    :ok
  end
  def validate(_), do: :error

  defp has_first_item_string([first | _]) when is_binary(first), do: true
  defp has_first_item_string(_), do: false
end
