defmodule :"additionalProperties-non-ASCII pattern with additionalProperties" do
  import Regex

  def validate(object) when is_map(object) do
    additional_properties_valid? = validate_additional_properties(object)

    if additional_properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_additional_properties(object) do
    allowed_pattern = ~r/^á/
    disallowed_keys = Map.keys(object)
                     |> Enum.filter(fn key -> not Regex.match?(allowed_pattern, key) end)

    Enum.empty?(disallowed_keys)
  end
end
