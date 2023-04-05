defmodule :"items-a schema given for items" do
  def validate(value) when is_list(value) do
    if is_items_valid?(value) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp is_items_valid?(items) do
    Enum.all?(items, &is_integer/1)
  end
end
