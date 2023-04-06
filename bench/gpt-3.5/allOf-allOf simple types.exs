defmodule :"allOf-allOf simple types-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    if validate_maximum(object) == :ok and validate_minimum(object) == :ok do
      :ok
    else
      :error
    end
  end

  defp validate_maximum(object) do
    case Map.get(object, "maximum") do
      nil -> :ok
      value when is_integer(value) and value <= 30 -> :ok
      _ -> :error
    end
  end

  defp validate_minimum(object) do
    case Map.get(object, "minimum") do
      nil -> :ok
      value when is_integer(value) and value >= 20 -> :ok
      _ -> :error
    end
  end
end