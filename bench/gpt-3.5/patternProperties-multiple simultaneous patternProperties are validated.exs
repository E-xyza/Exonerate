defmodule :"multiple simultaneous patternProperties are validated-gpt-3.5" do
  def validate(value) when is_map(value) do
    validate_object(value)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Enum.all?(object, fn {key, value} -> validate_property(key, value) end) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_property(key, value) do
    case Regex.match?("a*", key) do
      true ->
        validate_integer(value)

      false ->
        case Regex.match?("aaa*", key) do
          true -> validate_maximum(value, 20)
          false -> true
        end
    end
  end

  defp validate_integer(value) do
    case value do
      n when is_integer(n) -> :ok
      _ -> :error
    end
  end

  defp validate_maximum(value, maximum) do
    case value do
      n when is_integer(n) and n <= maximum -> :ok
      _ -> :error
    end
  end
end