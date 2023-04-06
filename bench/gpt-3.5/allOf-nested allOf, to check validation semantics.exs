defmodule :"allOf-nested allOf, to check validation semantics-gpt-3.5" do
  def validate(object) when is_nil(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"allOf" => [subschema]} = object) do
    with {:ok, _} <- validate_subschema(subschema, object) do
      :ok
    else
      _ -> :error
    end
  end

  def validate(%{"allOf" => [subschema | subschemas]} = object) do
    with {:ok, intermediate} <- validate_subschema(subschema, object),
         {:ok, result} <- validate(%{"allOf" => subschemas, "type" => intermediate}) do
      {:ok, result}
    else
      _ -> :error
    end
  end

  def validate(object) do
    with {"type", "null"} <- Enum.find(object, &(&1 == "type")) do
      :ok
    else
      _ -> :error
    end
  end

  defp validate_subschema(%{"type" => "array", "items" => subschema}, object) do
    if is_list(object) do
      for item <- object do
        validate_subschema(subschema, item)
      end
    else
      :error
    end
  end

  defp validate_subschema(%{"type" => "object", "properties" => properties}, object) do
    if is_map(object) do
      for {key, subschema} <- properties do
        validate_subschema(subschema, object[key])
      end
    else
      :error
    end
  end

  defp validate_subschema(%{"type" => "string", "pattern" => pattern}, object) do
    if is_binary(object) and String.match?(object, ~r/#{pattern}/) do
      {:ok, object}
    else
      :error
    end
  end

  defp validate_subschema(%{"type" => "number"}, object) when is_number(object) do
    {:ok, object}
  end

  defp validate_subschema(%{"type" => "integer"}, object) when is_integer(object) do
    {:ok, object}
  end

  defp validate_subschema(%{"type" => "boolean"}, object) when is_boolean(object) do
    {:ok, object}
  end

  defp validate_subschema(%{"enum" => enum}, object) do
    if Enum.member?(enum, object) do
      {:ok, object}
    else
      :error
    end
  end

  defp validate_subschema(%{"not" => subschema}, object) do
    case validate_subschema(subschema, object) do
      :error -> {:ok, object}
      _ -> :error
    end
  end

  defp validate_subschema(%{"allOf" => subschemas}, object) do
    for subschema <- subschemas, {:ok, intermediate} <- validate_subschema(subschema, object) do
      object = intermediate
    end

    {:ok, object}
  end

  defp validate_subschema(%{"anyOf" => subschemas}, object) do
    if Enum.member?(Enum.map(subschemas, &validate_subschema(&1, object)), :ok) do
      {:ok, object}
    else
      :error
    end
  end

  defp validate_subschema(%{"oneOf" => subschemas}, object) do
    case Enum.filter(Enum.map(subschemas, &validate_subschema(&1, object)), :ok) do
      [result] -> result
      _ -> :error
    end
  end
end