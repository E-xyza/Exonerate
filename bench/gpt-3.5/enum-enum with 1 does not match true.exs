defmodule :"enum-enum with 1 does not match true-gpt-3.5" do
  def validate(:[1]), do: :ok
  def validate(_), do: :error
end
