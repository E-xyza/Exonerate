defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent additionalProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object) do
      {:ok, _} -> :ok
      {:error, error} -> error
    end
  end

  def validate(object) do
    :error
  end

  defp validate_properties(object, schema \\ %{}) do
    case schema do
      %{"type" => "object"} ->
        case is_map(object) do
          true -> {:ok, object}
          false -> {:error, "Object expected"}
        end

      %{"type" => "string"} ->
        case is_binary(object) do
          true -> {:ok, object}
          false -> {:error, "String expected"}
        end

      %{"additionalProperties" => true} ->
        {:ok, object}

      %{"unevaluatedProperties" => false} ->
        validate_properties_with_properties(object, %{})

      %{"properties" => properties} ->
        validate_properties_with_properties(object, properties)

      _ ->
        {:error, "Unknown schema type"}
    end
  end

  defp validate_properties_with_properties(object, properties) do
    case is_map(object) do
      false ->
        {:error, "Object expected"}

      true ->
        case Enum.all?(Map.keys(properties), &Map.has_key?(object, &1)) do
          false ->
            {:error, "Missing properties"}

          true ->
            case Enum.reduce(properties, {:ok, %{}}, fn {key, schema}, {result, obj_acc} ->
                   case validate_properties(Map.get(object, key), schema) do
                     {:ok, validated_obj} ->
                       case Map.put(obj_acc, key, validated_obj) do
                         updated_object -> {:ok, result, updated_object}
                       end

                     {:error, error} ->
                       {:error, error}
                   end
                 end) do
              {:ok, result, updated_object} ->
                case Map.merge(object, updated_object) do
                  merged_object when is_map(merged_object) -> {:ok, merged_object}
                  _ -> {:error, "Failed to merge properties"}
                end

              {:error, error} ->
                {:error, error}
            end
        end
    end
  end
end