defmodule :"required validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(map) do
    required_fields = Enum.map(required(map), &validate_field(&1, map))
    optional_fields = Enum.map(optional(map), &validate_field(&1, map, false))

    if Enum.all?(required_fields ++ optional_fields, &(&1 == :ok)) do
      :ok
    else
      :error
    end
  end

  defp validate_field(field, map, required? \\ true) do
    if required?(map, field) do
      case Map.has_key?(map, field) do
        true -> :ok
        false -> :error
      end
    else
      :ok
    end
  end

  defp required(map) do
    Map.get(map, "required", [])
  end

  defp optional(map) do
    Map.keys(Map.delete(map, "required"))
  end

  defp required?(map, field) do
    field in required(map)
  end
end
