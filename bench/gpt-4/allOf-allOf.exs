defmodule :"allOf-allOf" do
  def validate(value) when is_map(value) and has_required_properties(value), do: :ok
  def validate(_), do: :error

  defp has_required_properties(value) do
    has_bar_property(value) and has_foo_property(value)
  end

  defp has_bar_property(%{"bar" => bar}) when is_integer(bar), do: true
  defp has_bar_property(_), do: false

  defp has_foo_property(%{"foo" => foo}) when is_binary(foo), do: true
  defp has_foo_property(_), do: false
end
