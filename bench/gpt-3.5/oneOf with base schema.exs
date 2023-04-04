defmodule :"oneOf with base schema-gpt-3.5" do
  def validate(object) when is_binary(object) do
    case Jason.decode(object) do
      {:error, _} -> :error
      {data, _} -> validate(data)
    end
  end

  def validate(object) when is_map(object) do
    case validate_type(object, "string") do
      :ok -> validate_one_of(object)
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_type(object, "string") when is_binary(object) do
    :ok
  end

  defp validate_type(_, _) do
    :error
  end

  defp validate_one_of(object) when is_map(object) do
    case object["oneOf"] do
      nil ->
        :ok

      [first | _] ->
        case validate_one(first, object) do
          :ok -> :ok
          _ -> validate_one_of(Map.delete(object, "oneOf"))
        end
    end
  end

  defp validate_one_of(_, _) do
    :error
  end

  defp validate_one(schema, object) when is_map(schema) and map_size(schema) == 1 do
    [{key, value}] = schema

    case key do
      "type" -> validate_type(object, value)
      "minLength" -> validate_min_length(object, value)
      "maxLength" -> validate_max_length(object, value)
      _ -> :error
    end
  end

  defp validate_one(_, _) do
    :error
  end

  defp validate_min_length(object, length) when is_binary(object) do
    if byte_size(object) >= length do
      :ok
    else
      :error
    end
  end

  defp validate_min_length(_, _) do
    :error
  end

  defp validate_max_length(object, length) when is_binary(object) do
    if byte_size(object) <= length do
      :ok
    else
      :error
    end
  end

  defp validate_max_length(_, _) do
    :error
  end
end
