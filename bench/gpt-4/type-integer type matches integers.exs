defmodule :"type-integer type matches integers" do
  def validate(value) when is_integer(value), do: :ok
  def validate(_), do: :error
end
