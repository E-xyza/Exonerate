defmodule :"enum-heterogeneous enum validation" do
  def validate(value) when value in [6, "foo", [], true, %{"foo" => 12}], do: :ok
  def validate(_), do: :error
end
