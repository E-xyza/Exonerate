defmodule :"properties-properties, patternProperties, additionalProperties interaction" do
  def validate(object) when is_map(object) do
    properties_valid? = validate_properties(object)
    pattern_properties_valid? = validate_pattern_properties(object)
    additional_properties_valid? = validate_additional_properties(object)

    if properties_valid? and pattern_properties_valid? and additional_properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_properties(%{"foo" => foo, "bar" => bar}) do
    is_list(foo) and length(foo) <= 3 and is_list(bar)
  end
  defp validate_properties(%{"foo" => foo}), do: is_list(foo) and length(foo) <= 3
  defp validate_properties(%{"bar" => bar}), do: is_list(bar)
  defp validate_properties(%{}), do: true

  defp validate_pattern_properties(object) do
    object
    |> Enum.filter(fn {k, _} -> Regex.match?(~r/f.o/, k) end)
    |> Enum.all?(fn {_, v} -> is_list(v) and length(v) >= 2 end)
  end

  defp validate_additional_properties(object) do
    object
    |> Enum.reject(fn {k, _} -> k == "foo" or k == "bar" or Regex.match?(~r/f.o/, k) end)
    |> Enum.all?(fn {_, v} -> is_integer(v) end)
  end
end
