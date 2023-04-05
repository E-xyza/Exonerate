defmodule :"invalid type for default" do
  def validate(value) when is_map(value) and has_valid_foo_property(value), do: :ok
  def validate(_), do: :error

  defp has_valid_foo_property(%{"foo" => foo_value}) when is_integer(foo_value), do: true
  defp has_valid_foo_property(%{}), do: true
  defp has_valid_foo_property(_), do: false
end
