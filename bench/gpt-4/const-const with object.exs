defmodule :"const with object" do
  def validate(%{"baz" => "bax", "foo" => "bar"}), do: :ok
  def validate(_), do: :error
end
