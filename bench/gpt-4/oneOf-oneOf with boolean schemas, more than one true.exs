defmodule :"oneOf with boolean schemas, more than one true" do
  def validate(true), do: :ok
  def validate(false), do: :error
  def validate(_), do: :error
end
