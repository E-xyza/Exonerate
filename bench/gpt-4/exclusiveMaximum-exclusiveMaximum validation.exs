defmodule :"exclusiveMaximum-exclusiveMaximum validation" do
  def validate(value) when is_number(value) and value < 3.0, do: :ok
  def validate(_), do: :error
end
