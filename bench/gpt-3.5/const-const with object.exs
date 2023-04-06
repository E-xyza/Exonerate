defmodule :"const-const with object-gpt-3.5" do
  def validate(%{"baz" => "bax", "foo" => "bar"}) do
    :ok
  end

  def validate(_) do
    :error
  end
end