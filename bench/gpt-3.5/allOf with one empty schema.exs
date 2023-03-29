defmodule :"allOf with one empty schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_all_of(object) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(_) do
    {:error, "Invalid input"}
  end

  defp validate_all_of(object) do
    case object["allOf"] do
      [sub_schema | _] -> validate_sub_schema(sub_schema, object)
      [] -> {:ok, nil}
      nil -> {:ok, nil}
      _ -> {:error, "Invalid schema"}
    end
  end

  defp validate_sub_schema(_, _) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "object"}, object) when is_map(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "array"}, object) when is_list(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "string"}, object) when is_binary(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "number"}, object) when is_number(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "integer"}, object) when is_integer(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => "boolean"}, object) when is_boolean(object) do
    {:ok, nil}
  end

  defp validate_sub_schema(%{"type" => _} = schema, _) do
    {:error, "Invalid input type for " <> inspect(schema)}
  end

  defp validate_sub_schema(%{} = schema, object) do
    for {key, value} <- schema do
      validate_keyword(key, value, object)
    end

    {:ok, nil}
  end

  defp validate_keyword("allOf", _, _) do
    {:error, "Cannot nest \"allOf\" schema keyword"}
  end

  defp validate_keyword("type", value, object) do
    case value do
      "object" when is_map(object) -> {:ok, nil}
      "array" when is_list(object) -> {:ok, nil}
      "string" when is_binary(object) -> {:ok, nil}
      "number" when is_number(object) -> {:ok, nil}
      "integer" when is_integer(object) -> {:ok, nil}
      "boolean" when is_boolean(object) -> {:ok, nil}
      _ -> {:error, "Invalid input type"}
    end
  end

  defp validate_keyword(_, _, _) do
    {:ok, nil}
  end
end
