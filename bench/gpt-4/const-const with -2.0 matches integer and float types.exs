defmodule :"const-const with -2.0 matches integer and float types" do
  def validate(-2.0), do: :ok
  def validate(-2), do: :ok
  def validate(_), do: :error
end
