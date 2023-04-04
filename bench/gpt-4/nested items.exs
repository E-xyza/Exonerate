defmodule :"nested items" do
  def validate(value) when is_list(value) do
    Enum.all?(value, &validate_item_level_1/1) and :ok || :error
  end
  def validate(_), do: :error

  defp validate_item_level_1(item) when is_list(item) do
    Enum.all?(item, &validate_item_level_2/1)
  end
  defp validate_item_level_1(_), do: false

  defp validate_item_level_2(item) when is_list(item) do
    Enum.all?(item, &validate_item_level_3/1)
  end
  defp validate_item_level_2(_), do: false

  defp validate_item_level_3(item) when is_list(item) do
    Enum.all?(item, &validate_item_level_4/1)
  end
  defp validate_item_level_3(_), do: false

  defp validate_item_level_4(item) when is_number(item), do: true
  defp validate_item_level_4(_), do: false
end
