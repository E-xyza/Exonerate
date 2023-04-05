defmodule :"const with array" do
  def validate([%{"foo" => "bar"}]), do: :ok
  def validate(_), do: :error
end
