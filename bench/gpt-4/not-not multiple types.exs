defmodule :"not multiple types" do
  def validate(object) when is_integer(object) or is_boolean(object), do: :error
  def validate(_), do: :ok
end
