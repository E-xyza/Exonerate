defmodule :"allOf-allOf with the first empty schema" do
  def validate(value) when is_number(value), do: :ok
  def validate(_), do: :error
end
