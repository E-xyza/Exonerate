defmodule :"oneOf-oneOf with boolean schemas, one true" do
  def validate(true), do: :ok
  def validate(false), do: :ok
  def validate(_), do: :error
end
