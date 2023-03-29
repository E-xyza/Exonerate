defmodule :"escaped pointer ref-gpt-3.5" do
  @jsonschema %{
    "$defs" => %{
      "percent%field" => %{"type" => "integer"},
      "slash/field" => %{"type" => "integer"},
      "tilde~field" => %{"type" => "integer"}
    },
    "properties" => %{
      "percent" => %{"$ref" => "#/$defs/percent%25field"},
      "slash" => %{"$ref" => "#/$defs/slash~1field"},
      "tilde" => %{"$ref" => "#/$defs/tilde~0field"}
    }
  }
  def validate(object) when is_map(object) do
    try do
      validate_object(object, @jsonschema)
      :ok
    rescue
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{}, _) do
    :ok
  end

  defp validate_object(%{key => value} = object, schema) do
    case Map.get(schema, "properties") do
      nil ->
        case Map.get(schema, "type") do
          "object" -> validate_object(value, schema)
          "integer" when is_integer(value) -> :ok
          _ -> :error
        end

      properties_schema ->
        case Map.get(properties_schema, key) do
          nil ->
            case Map.get(properties_schema, "$ref") do
              nil ->
                case Map.get(schema, "additionalProperties") do
                  false -> :error
                  sub_schema -> validate_object(object, sub_schema)
                end

              ref when is_binary(ref) ->
                {_, property} = ref |> String.split("#/") |> List.last() |> String.split("/")
                validate_object(object, Map.get(schema, "$defs", %{}) |> Map.get(property, %{}))
            end

          key_schema ->
            validate_object(value, key_schema)
        end
    end
  end
end
