defmodule :"allOf" do
  
defmodule :"allOf-allOf" do
  def validate(object) when is_map(object) do
    case validate_schema(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_), do: :error

  defp validate_schema(object) do
    for schema <- schema_list() do
      case validate_object(object, schema) do
        true -> :ok
        false -> false
      end
    end
  end

  defp validate_object(object, schema) do
    case Map.has_key?(object, schema["required"]) do
      true ->
        Enum.reduce(schema["required"], true, fn key, acc ->
          acc and Map.has_key?(object, key) and json_type_match?(object[key], schema["properties"][key])
        end)
      false -> true
    end
  end

  defp json_type_match?(value, schema) do
    case schema["type"] do
      "integer" -> is_integer(value)
      "string" -> is_binary(value)
      _ -> false
    end
  end

  defp schema_list() do
    [{"properties" => %{"bar" => %{"type" => "integer"}},"required" => ["bar"]},
     {"properties" => %{"foo" => %{"type" => "string"}},"required" => ["foo"]}]
  end
end

end
