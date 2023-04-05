defmodule :"unevaluatedItems-unevaluatedItems with nested items" do
  def validate(value) when is_list(value) and has_first_item_string(value) do
    :ok
  end
  def validate(_), do: :error

  defp has_first_item_string([first | _]) when is_binary(first), do: true
  defp has_first_item_string(_), do: false
end
