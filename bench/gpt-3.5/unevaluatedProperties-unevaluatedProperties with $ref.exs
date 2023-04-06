defmodule :"unevaluatedProperties-unevaluatedProperties with $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object, schema()) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error

  defp schema do
    {"$defs" => %{"bar" => %{"properties" => %{"bar" => %{"type" => "string"}}}},
     "$ref" => "#/$defs/bar",
     "properties" => %{"foo" => %{"type" => "string"}},
     "type" => "object",
     "unevaluatedProperties" => false}
  end

  defp validate_object(object, schema) when is_map(schema) and map_size(schema) > 0 do
    case schema["type"] do
      "object" ->
        case schema["properties"] do
          props when is_map(props) ->
            for {key, value} <- props do
              case Map.fetch(object, key) do
                {:ok, val} ->
                  case validate_object(val, value) do
                    :ok -> :ok
                    _ -> return_error()
                  end
                _ when is_boolean(value["required"]) and value["required"] == true ->
                  return_error()
                _ -> :ok
              end
            end
            case schema["unevaluatedProperties"] do
              true ->
                object_keys = Map.keys(object)
                allowed_keys = Map.keys(props)
                case Enum.all?(object_keys, &Enum.member?(allowed_keys, &1)) do
                  true -> :ok
                  _ -> return_error()
                end
              _ -> :ok
            end
          _ -> :ok
        end
      "array" ->
        for elem <- object do
          case validate_object(elem, schema["items"]) do
            :ok -> :ok
            _ -> return_error()
          end
        end
      "string" ->
        case schema["maxLength"] do
          length when is_integer(length) ->
            case String.length(object) <= length do
              true -> :ok
              _ -> return_error()
            end
          _ -> :ok
        end
      "integer" ->
        case schema["minimum"] do
          min when is_integer(min) ->
            case object >= min do
              true -> :ok
              _ -> return_error()
            end
          _ -> :ok
        end
      _ -> :ok
    end
  end

  defp validate_object(_, _), do: :ok

  defp return_error(), do: {:error, "Validation error"}
end
