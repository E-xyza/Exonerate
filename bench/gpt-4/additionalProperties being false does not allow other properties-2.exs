defmodule :"additionalProperties being false does not allow other properties" do
  import Regex

  def validate(object) when is_map(object) do
    properties_valid? = validate_properties(object)
    additional_properties_valid? = validate_additional_properties(object)

    if properties_valid? and additional_properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_properties(object) do
    properties = ["bar", "foo"]
    Enum.all?(properties, fn key -> Map.has_key?(object, key) end)
  end

  defp validate_additional_properties(object) do
    allowed_pattern = ~r/^v/
    disallowed_keys = Map.keys(object)
                     |> Enum.filter(fn key -> not Regex.match?(allowed_pattern, key) end)

    Enum.all?(disallowed_keys, fn key -> not Map.has_key?(object, key) end)
  end
end
