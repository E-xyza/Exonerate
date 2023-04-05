defmodule :"oneOf with empty schema" do
  def validate(object) when is_number(object), do: :ok
  def validate(_), do: :ok
end
