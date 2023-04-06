defmodule :"unevaluatedProperties-unevaluatedProperties with dependentSchemas-gpt-3.5" do
  def validate(input) when is_map(input) do
    case validate_object(input) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    properties_valid = validate_properties(object)
    schema_valid = validate_dependent_schema(object)

    if properties_valid and schema_valid do
      :ok
    else
      :error
    end
  end

  defp validate_properties(object) do
    case Map.get(object, "foo") do
      nil -> true
      value -> is_binary(value)
    end
  end

  defp validate_dependent_schema(object) do
    case Map.get(object, "foo") do
      value when is_binary(value) ->
        case Map.get(object, "bar") do
          "bar" -> :ok
          _ -> :error
        end

      _ ->
        true
    end
  end
end