defmodule :"dependentSchemas-single dependency" do
  def validate(value) when is_map(value) and complies_with_dependencies(value), do: :ok
  def validate(_), do: :error

  defp complies_with_dependencies(value) do
    case Map.has_key?(value, "bar") do
      true -> has_required_properties(value)
      false -> true
    end
  end

  defp has_required_properties(%{"bar" => bar, "foo" => foo}) when is_integer(bar) and is_integer(foo), do: true
  defp has_required_properties(_), do: false
end
