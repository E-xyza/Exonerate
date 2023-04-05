defmodule :"format-validation of IPv6 addresses-gpt-3.5" do
  def validate(json) when is_map(json) do
    validate_object(json)
  end

  def validate(_) do
    :error
  end

  defp validate_object(json) do
    case Map.has_key?(json, "format") && json["format"] == "ipv6" do
      true -> :ok
      false -> :error
    end
  end
end
