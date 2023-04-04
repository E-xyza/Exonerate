defmodule :"nested anyOf, to check validation semantics" do
  def validate(value) when is_nil(value), do: :ok
  def validate(_), do: :error
end
