defmodule :"unevaluatedProperties-unevaluatedProperties with anyOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case validate_schema(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  defp validate_schema(%{"type" => "object"}) do
    :ok
  end

  defp validate_schema(%{"type" => "array"}) do
    :ok
  end

  defp validate_schema(%{"type" => "string"} = schema) do
    case schema["format"] do
      "email" -> validate_email(schema)
      _ -> :ok
    end
  end

  defp validate_schema(%{"type" => "number"}) do
    :ok
  end

  defp validate_schema(%{"type" => "integer"}) do
    :ok
  end

  defp validate_schema(%{"type" => "boolean"}) do
    :ok
  end

  defp validate_schema(%{"anyOf" => any_of}) do
    case Enum.map(any_of, &validate_schema/1) do
      [:ok | _] -> :ok
      _ -> :error
    end
  end

  defp validate_schema(%{"properties" => props} = schema) do
    case Enum.all?(props, fn {key, prop} ->
           case Map.get(schema, "required") do
             [required_key | _] when required_key == key -> Map.has_key?(prop, "const")
             _ -> true
           end
         end) do
      true -> :ok
      _ -> :error
    end
  end

  defp validate_schema(_) do
    :error
  end

  defp validate_email(%{"pattern" => pattern}) do
    case Regex.match?(~r/#{pattern}/, "test@example.com") do
      true -> :ok
      false -> :error
    end
  end
end
