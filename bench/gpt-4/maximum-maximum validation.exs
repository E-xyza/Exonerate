defmodule :"maximum-maximum validation" do
  def validate(number) when is_number(number) and number <= 3.0, do: :ok
  def validate(_), do: :error
end
