defmodule :"unevaluatedProperties with $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case match_properties(object, schema()) do
      {true, _} -> :ok
      {false, error} -> error
    end
  end

  defp match_properties(object, %{"type" => "object", "properties" => properties}) do
    match_properties_with_optional_fields(object, properties, [])
  end

  defp match_properties_with_optional_fields(object, [], errors) do
    {true, errors}
  end

  defp match_properties_with_optional_fields(object, [{key, schema} | rest], errors) do
    case match_property(object, key, schema) do
      :ok -> match_properties_with_optional_fields(object, rest, errors)
      error -> match_properties_with_optional_fields(object, rest, [error | errors])
    end
  end

  defp match_property(object, key, schema) do
    case Map.get(object, key) do
      nil ->
        error("required property missing: #{key}")

      value ->
        case match_value(value, schema) do
          true -> :ok
          false -> error("property value does not match schema: #{key}")
        end
    end
  end

  defp match_value(value, %{"type" => "string"}) do
    is_binary(value)
  end

  defp error(message) do
    {:error, message}
  end

  defp schema do
    %{
      "$defs" => %{"bar" => %{"properties" => %{"bar" => %{"type" => "string"}}}},
      "$ref" => "#/$defs/bar",
      "properties" => %{"foo" => %{"type" => "string"}},
      "type" => "object",
      "unevaluatedProperties" => false
    }
  end
end