defmodule :"const-const with null" do
  def validate(nil), do: :ok
  def validate(_), do: :error
end
