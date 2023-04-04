defmodule :"minimum validation with signed integer" do
  def validate(number) when is_number(number) and number >= -2, do: :ok
  def validate(_), do: :error
end
