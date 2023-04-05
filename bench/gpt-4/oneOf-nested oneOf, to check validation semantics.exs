defmodule :"oneOf-nested oneOf, to check validation semantics" do
  def validate(null) do
    :ok
  end

  def validate(_), do: :error
end
