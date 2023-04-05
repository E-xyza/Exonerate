defmodule :"property named $ref, containing an actual $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.get(object, "$ref") do
      nil -> validate_properties(object)
      ref -> validate_ref(ref, object)
    end
  end

  defp validate_properties(object) do
    case Map.get(object, "properties") do
      nil -> false
      properties -> Enum.all?(Map.values(properties), fn prop -> validate_object(prop) end)
    end
  end

  defp validate_ref(ref, object) do
    case resolve_ref(ref) do
      {:ok, schema} -> validate_object(Map.merge(schema, object))
      {:error, _} -> false
    end
  end

  defp resolve_ref(ref) do
    case ref do
      "#/$defs/is-string" -> {:ok, %{"type" => "string"}}
      _ -> {:error, :unknown_ref}
    end
  end
end