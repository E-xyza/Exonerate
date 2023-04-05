defmodule :"type-type as array with one item" do
  def validate(value) when is_binary(value), do: :ok
  def validate(_), do: :error
end
