defmodule :"enum-enum with 0 does not match false" do
  def validate(0), do: :ok
  def validate(_), do: :error
end
