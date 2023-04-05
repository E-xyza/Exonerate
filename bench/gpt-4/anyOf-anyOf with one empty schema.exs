defmodule :"anyOf-anyOf with one empty schema" do
  def validate(value) when is_number(value), do: :ok
  def validate(_), do: :ok
end
