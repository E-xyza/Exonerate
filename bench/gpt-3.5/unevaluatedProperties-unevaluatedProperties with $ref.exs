defmodule :"unevaluatedProperties with $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object) do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "foo") do
      true -> validate_properties(object)
      _ -> false
    end
  end

  defp validate_properties(object) do
    case Map.has_key?(object, "bar") do
      true ->
        case Map.get(object, "bar") do
          value when is_map(value) ->
            case Map.has_key?(value, "bar") do
              true -> validate_type(Map.get(value, "bar"), "string")
              _ -> false
            end

          _ ->
            false
        end

      _ ->
        validate_type(object, "string")
    end
  end

  defp validate_type(value, "string") do
    is_binary(value)
  end

  defp validate_type(value, "object") do
    is_map(value)
  end

  defp validate_type(value, "array") do
    is_list(value)
  end

  defp validate_type(value, "number") do
    is_number(value)
  end

  defp validate_type(_, _) do
    false
  end
end
