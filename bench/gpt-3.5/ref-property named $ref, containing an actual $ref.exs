defmodule :"ref-property named $ref, containing an actual $ref-gpt-3.5" do
  @schema %{
    "$defs" => %{"is-string" => %{"type" => "string"}},
    "properties" => %{"$ref" => %{"$ref" => "#/$defs/is-string"}}
  }
  def validate(object) when is_map(object) do
    case validate_object(object, @schema) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object, schema) do
    case Map.has_key?(schema, "properties") do
      true -> validate_properties(object, schema["properties"])
      false -> :ok
    end
  end

  defp validate_properties(object, properties) do
    Enum.reduce(
      Map.keys(properties),
      :ok,
      fn prop, result ->
        case Map.has_key?(object, prop) do
          true -> validate_object(Map.get(object, prop), properties[prop])
          false -> :error
        end
        |> resolve_result(result)
      end
    )
  end

  defp resolve_result(result1, result2) do
    if result1 == :ok and result2 == :ok do
      :ok
    else
      :error
    end
  end
end