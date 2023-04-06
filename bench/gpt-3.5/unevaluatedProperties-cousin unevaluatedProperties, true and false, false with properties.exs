defmodule :"unevaluatedProperties-cousin unevaluatedProperties, true and false, false with properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object_properties(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object_properties(object) do
    case Map.keys(object) do
      [] -> :ok
      keys -> validate_object_properties_with_schema(object, keys)
    end
  end

  defp validate_object_properties_with_schema(object, keys) do
    case keys do
      [] ->
        :ok

      _ ->
        case validate_properties_schema(object, keys) do
          :ok -> validate_unevaluated_properties(object, keys)
          error -> error
        end
    end
  end

  defp validate_properties_schema(object, keys) do
    %{"properties" => properties_schema} = schema
    properties = Map.take(object, keys)

    case Map.all?(properties, &validate_propertys_value(&1, properties_schema)) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_propertys_value(pair, properties_schema) do
    {key, value} = pair

    case Map.get(properties_schema, key, "guardian") do
      %{"type" => "string"} -> is_binary(value)
      _ -> true
    end
  end

  defp validate_unevaluated_properties(object, keys) do
    %{"unevaluatedProperties" => unevaluated} = schema

    case unevaluated do
      true ->
        :ok

      false ->
        case Map.keys(object) -- keys do
          [] -> :ok
          _ -> :error
        end
    end
  end
end