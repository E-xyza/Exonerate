defmodule :"unevaluatedProperties with nested properties" do
  
defmodule JsonSchema do
  def validate(object) when is_map(object) do
    case validate_object(object, %{
          "allOf":[{"properties":{"bar":{"type":"string"}}}],
          "properties":{"foo":{"type":"string"}},
          "type":"object",
          "unevaluatedProperties":false
        }) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error

  defp validate_object(object, schema) do
    case Map.get(schema, "type") do
      "object" -> validate_object_properties(object, schema)

      _ -> :error
    end
  end

  defp validate_object_properties(object, schema) do
    case Map.get(schema, "properties") do
      nil -> :ok

      properties ->
        case Map.keys(properties) |> Enum.map(fn key ->
                      case {Map.get(properties, key), Map.get(object, key)} do
                        {"type", _} -> validate_type(Map.get(object, key), Map.get(properties, key))

                        _ -> :error
                      end
                    end) do
          errors when Enum.all?(errors, &(&1 == :ok)) -> :ok

          _ -> :error
        end
    end
  end

  defp validate_type(value, schema) do
    case Map.get(schema, "type") do
      "string" when is_binary(value) -> :ok

      _ -> :error
    end
  end
end

end
