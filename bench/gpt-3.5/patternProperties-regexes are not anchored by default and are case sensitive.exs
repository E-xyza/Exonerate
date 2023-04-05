defmodule :"regexes are not anchored by default and are case sensitive-gpt-3.5" do
  def validate(value) do
    case value do
      %{"patternProperties" => pattern_properties} ->
        case validate_pattern_properties(value, pattern_properties) do
          true -> :ok
          false -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_pattern_properties(value, pattern_properties) do
    Enum.all?(pattern_properties, fn {pattern, property_schema} ->
      case Regex.regex?(~r/^X_|[0-9]{2,}$/, pattern) do
        true ->
          Enum.all?(Map.keys(value), fn key ->
            case Regex.regex?(~r/^#{pattern}$/, key) do
              true ->
                case validate_property(value[key], property_schema) do
                  :ok -> true
                  :error -> false
                end

              false ->
                true
            end
          end)

        false ->
          true
      end
    end)
  end

  defp validate_property(value, schema) do
    case schema do
      %{"type" => "boolean"} -> is_boolean(value)
      %{"type" => "string"} -> is_binary(value)
      %{"type" => "object"} -> is_map(value)
      _ -> :ok
    end
  end
end