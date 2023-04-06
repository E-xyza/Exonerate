defmodule :"unevaluatedProperties-unevaluatedProperties with nested properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object, %{properties: %{}, allOf: [], unevaluatedProperties: false})
  end

  def validate(_) do
    :error
  end

  defp validate_object(object, schema) when is_map(schema) do
    case Map.get(schema, "type") do
      "object" -> validate_object_type(object, schema)
      "string" -> validate_string(object, schema)
      _ -> :ok
    end
  end

  defp validate_object_type(object, schema) do
    case Map.get(schema, "properties") do
      %{} ->
        case Map.get(schema, "additionalProperties") do
          false -> validate_object_properties(object, schema, schema)
          _ -> :ok
        end

      properties ->
        case Map.get(schema, "unevaluatedProperties") do
          false -> validate_object_properties(object, properties, schema)
          _ -> validate_object_properties(object, properties, schema, true)
        end
    end
  end

  defp validate_object_properties(object, properties, schema, unevaluated \\ false) do
    case Map.equal(object, %{}) do
      true ->
        case unevaluated do
          true -> :ok
          false -> :error
        end

      false ->
        case Enum.all?(properties, fn {key, value} ->
               case Map.get(object, key) do
                 nil ->
                   case Map.get(value, "default") do
                     nil -> false
                     default -> true
                   end

                 val ->
                   validate_object(val, value) == :ok
               end
             end) do
          true ->
            case unevaluated do
              true -> validate_unevaluated_properties(object, properties, schema)
              false -> :ok
            end

          false ->
            :error
        end
    end
  end

  defp validate_unevaluated_properties(object, properties, schema) do
    case Map.get(schema, "additionalProperties") do
      false ->
        case Map.get(object, "__unevaluated__") do
          nil -> :ok
          _ -> :error
        end

      additional_schema ->
        case Map.get(object, "__unevaluated__") do
          nil ->
            validate_object_properties(object, additional_schema, schema)

          unevaluated ->
            case validate_object_properties(unevaluated, additional_schema, schema) do
              :ok ->
                case validate_object_properties(
                       object -- %{"__unevaluated__" => unevaluated},
                       properties,
                       schema
                     ) do
                  :ok -> :ok
                  :error -> :error
                end

              :error ->
                :error
            end
        end
    end
  end

  defp validate_string(object, schema) do
    case Map.get(schema, "format") do
      "date-time" ->
        case DateTime.from_iso8601(object) do
          {:ok, _} -> :ok
          _ -> :error
        end

      _ ->
        :ok
    end
  end
end