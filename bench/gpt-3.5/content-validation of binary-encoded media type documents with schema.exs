defmodule :"content-validation of binary-encoded media type documents with schema-gpt-3.5" do
  def validate(json) when is_map(json) do
    schema = %{
      "contentEncoding" => "base64",
      "contentMediaType" => "application/json",
      "contentSchema" => %{
        "properties" => %{"foo" => %{"type" => "string"}},
        "required" => ["foo"]
      }
    }

    case validate_with_schema(json, schema["contentSchema"]) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_with_schema(json, schema) when is_map(schema) do
    for {key, value} <- schema["properties"] do
      case Map.has_key?(json, key) do
        true ->
          case validate_with_schema(Map.get(json, key), value) do
            :ok -> :ok
            _ -> :error
          end

        false ->
          :error
      end
    end

    for required_key <- schema["required"] do
      if !Map.has_key?(json, required_key) do
        return(:error)
      end
    end

    :ok
  end

  defp validate_with_schema(json, schema) when schema == "string" do
    case is_binary(json) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_with_schema(json, schema) when schema == "number" do
    case is_number(json) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_with_schema(json, schema) when schema == "integer" do
    case is_integer(json) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_with_schema(json, schema) when schema == "boolean" do
    case is_boolean(json) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_with_schema(json, schema) when schema == "null" do
    case is_nil(json) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_with_schema(json, schema) when is_list(schema) do
    case json do
      [] -> :ok
      [{}, _ | _] -> :error
      [_ | tail] -> validate_with_schema(tail, schema)
      _ -> :error
    end
  end
end
