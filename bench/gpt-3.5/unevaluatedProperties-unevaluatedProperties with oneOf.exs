defmodule :"unevaluatedProperties-unevaluatedProperties with oneOf-gpt-3.5" do
  def validate(%{"type" => "object", "properties" => props} = object) do
    case validate_properties(props, object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(props, object) do
    props
    |> Enum.reduce(
      :ok,
      fn {key, schema}, result ->
        case Map.fetch(object, key) do
          {:ok, value} ->
            case validate_value(schema, value) do
              :ok -> result
              _ -> :error
            end

          _ ->
            if is_required(schema, key) do
              :error
            else
              result
            end
        end
      end
    )
  end

  defp is_required(schema, key) do
    with ["required" | _] <- schema["oneOf"],
         one_of_schema <- schema["oneOf"],
         %{"properties" => properties} = one_of_schema,
         key in Map.keys(properties) do
      true
    else
      _ -> false
    end
  end

  defp validate_value(%{"const" => value}, object) when object == value do
    :ok
  end

  defp validate_value(%{"type" => "string"}, object) when is_binary(object) do
    :ok
  end

  defp validate_value(_schema, _object) do
    :error
  end
end