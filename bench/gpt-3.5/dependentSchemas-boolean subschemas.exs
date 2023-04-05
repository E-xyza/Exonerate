defmodule :"boolean subschemas-gpt-3.5" do
  def validate(schema) when is_map(schema) do
    validate_object(schema)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{"type" => "object"}) do
    fn object -> is_map(object) end
  end

  defp validate_object(%{"dependentSchemas" => dependent_schemas}) do
    dependent_schemas
    |> Enum.all?(&validate_dependent_schema(&1))
    |> if do
      fn _ -> :ok end
    else
      fn _ -> :error end
    end
  end

  defp validate_object(_) do
    fn _ -> false end
  end

  defp validate_dependent_schema({schema_name, false}) do
    fn _ -> true end
  end

  defp validate_dependent_schema({schema_name, true}) do
    fn object -> apply(schema_name, :validate, [object]) == :ok end
  end
end
