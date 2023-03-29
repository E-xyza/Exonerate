defmodule :"items and subitems" do
  def validate(value) when is_list(value) and length(value) == 3 do
    Enum.all?(value, &validate_item/1) and :ok || :error
  end
  def validate(_), do: :error

  defp validate_item(item) do
    is_list(item) and length(item) == 2 and Enum.all?(item, &validate_sub_item/1)
  end

  defp validate_sub_item(sub_item) do
    is_map(sub_item) and Map.has_key?(sub_item, "foo")
  end
end
