defmodule :"const-const with 0 does not match other zero-like types" do
  def validate(0), do: :ok
  def validate(_), do: :error
end
