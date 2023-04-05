defmodule :"unevaluatedProperties-unevaluatedProperties with dependentSchemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    if dependent_schemas_valid?(object) and properties_valid?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp dependent_schemas_valid?(object) do
    dependent_schemas =
      Map.get(
        object,
        "dependentSchemas"
      )

    case dependent_schemas do
      nil ->
        true

      _ ->
        dependent_schemas
        |> Map.values()
        |> Enum.into(%{})
        |> Map.merge(object)
        |> properties_valid?()
    end
  end

  defp properties_valid?(object) do
    properties =
      Map.get(
        object,
        "properties"
      )

    case properties do
      nil ->
        true

      _ ->
        Enum.all?(
          Map.keys(properties),
          &(Map.has_key?(object, &1) and type_valid?(Map.get(object, &1), Map.get(properties, &1)))
        )
    end
  end

  defp type_valid?(value, schema) do
    case Map.get(schema, "type") do
      "string" -> is_binary(value)
      _ -> true
    end
  end
end
