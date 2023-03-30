defmodule :"invalid string value for default" do
  def validate(value) when is_map(value) and has_valid_bar_property(value), do: :ok
  def validate(_), do: :error

  defp has_valid_bar_property(%{"bar" => bar_value}) when is_binary(bar_value) and String.length(bar_value) >= 4, do: true
  defp has_valid_bar_property(%{}), do: true
  defp has_valid_bar_property(_), do: false
end
