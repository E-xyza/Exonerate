defmodule :"type-multiple types can be specified in an array" do
  def validate(value) when is_integer(value) or is_binary(value), do: :ok
  def validate(_), do: :error
end
