defmodule :"anyOf-anyOf" do
  def validate(value) when is_integer(value) or (is_number(value) and value >= 2), do: :ok
  def validate(_), do: :error
end
