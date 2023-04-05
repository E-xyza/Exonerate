defmodule :"enum-heterogeneous enum-with-null validation" do
  def validate(value) when value in [6, :nil], do: :ok
  def validate(_), do: :error
end
