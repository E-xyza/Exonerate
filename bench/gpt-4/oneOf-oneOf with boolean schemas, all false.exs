defmodule :"oneOf-oneOf with boolean schemas, all false" do
  def validate(object) when object == false, do: :ok
  def validate(_), do: :error
end
