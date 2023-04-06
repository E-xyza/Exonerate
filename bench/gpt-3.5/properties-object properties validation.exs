defmodule :"properties-object properties validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "foo") and Map.has_key?(object, "bar") do
      true -> validate_properties(object)
      false -> :error
    end
  end

  defp validate_properties(object) do
    case is_string(object["bar"]) and is_integer(object["foo"]) do
      true -> :ok
      false -> :error
    end
  end

  defp is_string(value) do
    case value do
      x when is_binary(x) -> true
      _ -> false
    end
  end

  defp is_integer(value) do
    case value do
      x when is_integer(x) -> true
      _ -> false
    end
  end
end