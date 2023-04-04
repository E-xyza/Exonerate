defmodule :"items + contains" do
  def validate(object) when is_list(object) do
    if Enum.all?(object, &(&1 % 3 == 0)) and Enum.all?(object, &(&1 % 2 == 0)) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
