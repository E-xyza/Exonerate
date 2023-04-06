defmodule :"properties-properties, patternProperties, additionalProperties interaction-gpt-3.5" do
  def validate(json) do
    case json do
      %{} ->
        :ok

      %{additionalProperties: additional_props} ->
        validate_additional_props(additional_props, json)

      _ ->
        :error
    end
  end

  defp validate_additional_props(true, _) do
    :ok
  end

  defp validate_additional_props(false, _) do
    :error
  end

  defp validate_additional_props(schema, json) do
    case validate_properties(schema, json) do
      :ok ->
        case validate_pattern_properties(schema, json) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_properties(properties_schema, json) do
    properties_schema
    |> Map.keys()
    |> Enum.reduce(
      :ok,
      fn key, acc ->
        case Map.has_key?(json, key) do
          true ->
            case validate_value(properties_schema[key], Map.get(json, key)) do
              :ok -> acc
              _ -> :error
            end

          false ->
            :error
        end
      end
    )
  end

  defp validate_pattern_properties(schema, json) do
    schema
    |> Map.keys()
    |> Enum.reduce(
      :ok,
      fn key, acc ->
        case String.contains?(key, ".") do
          true ->
            [prop, subprop] =
              String.split(
                key,
                ".",
                parts: 2
              )

            case Map.has_key?(json, prop) do
              true ->
                case Map.get(json, prop) do
                  [] ->
                    :ok

                  [subjson | _] when is_map(subjson) ->
                    case validate_value(schema[key], subjson) do
                      :ok -> acc
                      _ -> :error
                    end

                  [_ | _] ->
                    :error
                end

              false ->
                :error
            end

          false ->
            :error
        end
      end
    )
  end

  defp validate_value(schema, json) do
    case schema do
      "array" ->
        case json do
          [] -> :ok
          _ when is_list(json) -> :ok
          _ -> :error
        end

      "integer" ->
        (is_integer(json) and :ok) or :error

      "object" ->
        (is_map(json) and :ok) or :error

      "string" ->
        (is_binary(json) and :ok) or :error

      "number" ->
        (is_number(json) and :ok) or :error

      _ ->
        :error
    end
  end
end