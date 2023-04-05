defmodule :"enum-enum with true does not match 1" do
  def validate(true), do: :ok
  def validate(_), do: :error
end
