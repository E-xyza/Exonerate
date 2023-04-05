defmodule :"object properties validation-gpt-3.5" do
  def validate(%{"properties" => properties} = object) do
    case validate_object(properties, object) do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(properties, object) do
    Enum.all?(properties, fn {key, {"type", value}} ->
      validate_type(key, value, Map.get(object, key))
    end)
  end

  defp validate_type(_key, "string", value) when is_binary(value) do
    true
  end

  defp validate_type(_key, "integer", value) when is_integer(value) do
    true
  end

  defp validate_type(_key, "number", value) when is_number(value) do
    true
  end

  defp validate_type(_key, "boolean", value) when value == true or value == false do
    true
  end

  defp validate_type(_key, "array", value) when is_list(value) do
    validate_array(value)
  end

  defp validate_type(_key, "object", value) when is_map(value) do
    validate_object(value)
  end

  defp validate_type(_key, _value, _object) do
    false
  end

  defp validate_array(values) do
    Enum.all?(values, fn value ->
      [item_type] =
        Map.get(
          values,
          0
        )["type"]

      validate_type(nil, item_type, value)
    end)
  end
end