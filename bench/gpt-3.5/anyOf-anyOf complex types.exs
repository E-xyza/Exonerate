defmodule :"anyOf-anyOf complex types-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object_schema(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object_schema(object) do
    case validate_integer_schema(object) do
      :ok -> :ok
      :error -> validate_string_schema(object)
    end
  end

  defp validate_integer_schema(object) do
    case Map.get(object, "bar") do
      nil -> :error
      integer when is_integer(integer) -> :ok
      _ -> :error
    end
  end

  defp validate_string_schema(object) do
    case Map.get(object, "foo") do
      nil -> :error
      string when is_binary(string) -> :ok
      _ -> :error
    end
  end
end
