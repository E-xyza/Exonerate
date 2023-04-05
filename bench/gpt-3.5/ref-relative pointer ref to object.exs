defmodule :"relative pointer ref to object-gpt-3.5" do
  def validate(%{"$ref" => ref} = object) do
    json_schema = resolve_ref(ref)
    validate_schema(json_schema, object)
  end

  def validate(_) do
    :error
  end

  defp resolve_ref(ref) do
    json_schema = %{
      "properties" => %{"bar" => %{"$ref" => "#/properties/foo"}, "foo" => %{"type" => "integer"}}
    }

    case ref do
      "#/properties/foo" -> json_schema["properties"]["foo"]
      _ -> raise "Invalid reference: #{ref}"
    end
  end

  defp validate_schema(%{"type" => "integer"}, _object) do
    :ok
  end

  defp validate_schema(%{"type" => "object"}, object) when is_map(object) do
    :ok
  end

  defp validate_schema(_schema, _object) do
    :error
  end
end