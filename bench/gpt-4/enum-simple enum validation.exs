defmodule :"enum-simple enum validation" do
  def validate(value) when value in [1, 2, 3], do: :ok
  def validate(_), do: :error
end
