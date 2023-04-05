defmodule :"properties-properties with escaped characters-gpt-3.5" do
  def validate(%{} = object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{} = object) do
    %{"properties" => properties} = schema_parts()
    validate_properties(properties, object)
  end

  defp validate_object(_) do
    :error
  end

  defp validate_properties(properties, object) do
    Enum.reduce(properties, :ok, fn {key, property_schema}, result ->
      case Map.get(object, key) do
        nil -> :error
        value -> validate_property(property_schema, value)
      end
      |> validate_result(result)
    end)
  end

  defp validate_property(%{"type" => "number"}, value) when is_number(value) do
    :ok
  end

  defp validate_property(_property_schema, _value) do
    :error
  end

  defp validate_result(:error, _) do
    :error
  end

  defp validate_result(:ok, result) do
    result
  end

  defp schema_parts() do
    %{
      "properties" => %{
        "foo\tbar" => %{"type" => "number"},
        "foo\nbar" => %{"type" => "number"},
        "foo\fbar" => %{"type" => "number"},
        "foo\rbar" => %{"type" => "number"},
        "foo\"bar" => %{"type" => "number"},
        "foo\\bar" => %{"type" => "number"}
      }
    }
  end
end
