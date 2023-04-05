defmodule :"enum with 1 does not match true" do
  def validate(1), do: :ok
  def validate(_), do: :error
end
