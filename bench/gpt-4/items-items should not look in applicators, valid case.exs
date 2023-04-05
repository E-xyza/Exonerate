defmodule :"items-items should not look in applicators, valid case" do
  def validate(value) when is_list(value) do
    result = Enum.map(value, &validate_item/1)
    if Enum.all?(result, &(&1 == :ok)) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error

  defp validate_item(value) when is_number(value) do
    if value >= 5 do
      :ok
    else
      :error
    end
  end
  defp validate_item(_), do: :error
end
