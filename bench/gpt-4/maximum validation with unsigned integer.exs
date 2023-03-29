defmodule :"maximum validation with unsigned integer" do
  def validate(number) when is_number(number) and number <= 300, do: :ok
  def validate(_), do: :error
end
