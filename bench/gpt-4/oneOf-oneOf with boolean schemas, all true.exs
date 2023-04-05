defmodule :"oneOf-oneOf with boolean schemas, all true" do
  def validate(true), do: :ok
  def validate(false), do: :error
  def validate(_), do: :error
end
