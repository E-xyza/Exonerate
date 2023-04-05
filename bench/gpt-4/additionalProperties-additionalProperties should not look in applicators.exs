defmodule :"additionalProperties should not look in applicators" do
  def validate(object) when is_map(object) do
    if is_foo_property_valid?(object) and are_additional_properties_valid?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp is_foo_property_valid?(object) do
    case Map.get(object, "foo") do
      nil -> true
      _ -> true
    end
  end

  defp are_additional_properties_valid?(object) do
    keys = Map.keys(object)
    Enum.all?(keys, &is_additional_property_valid?/1)
  end

  defp is_additional_property_valid?(key) do
    allowed_properties = ["foo"]
    if key in allowed_properties do
      true
    else
      value = Map.get(object, key)
      is_boolean(value)
    end
  end
end
