defmodule :"oneOf-oneOf with base schema-gpt-3.5" do
  def validate(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, decoded_json} -> validate(decoded_json)
      _ -> :error
    end
  end

  def validate(value) when is_binary(value) do
    case read_keyword("type", "string") do
      "string" -> :ok
      _ -> :error
    end
  end

  def validate(value) when is_number(value) do
    case read_keyword("type", "number") do
      "number" -> :ok
      _ -> :error
    end
  end

  def validate(value) when is_nil(value) do
    case read_keyword("type", "null") do
      "null" -> :ok
      _ -> :error
    end
  end

  def validate(value) when is_boolean(value) do
    case read_keyword("type", "boolean") do
      "boolean" -> :ok
      _ -> :error
    end
  end

  def validate(object) when is_map(object) do
    case read_keyword("type", "object") do
      "object" -> :ok
      _ -> :error
    end
  end

  def validate(array) when is_list(array) do
    case read_keyword("type", "array") do
      "array" -> :ok
      _ -> :error
    end
  end

  def validate(value) when is_binary(value) do
    case read_property({"oneOf", 0}, "minLength") do
      length when is_integer(length) and byte_size(value) >= length -> :ok
      _ -> :error
    end
  end

  def validate(value) when is_binary(value) do
    case read_property({"oneOf", 1}, "maxLength") do
      length when is_integer(length) and byte_size(value) <= length -> :ok
      _ -> :error
    end
  end

  defp read_keyword(keyword, check) do
    case read_property(keyword) do
      value when value === check -> value
      _ -> :invalid
    end
  end

  defp read_property({prop, index \\ 0}, default \\ :undefined) do
    case read_property(prop) do
      [%{} | _rest] = list when is_list(list) ->
        case List.keyfind(list, index, prop) do
          {_index, value} -> value
          _ -> default
        end

      _ ->
        default
    end
  end

  defp read_property(prop, default \\ :undefined) do
    case read_keyword(prop, pos = 0) do
      :invalid ->
        case Jason.decode(prop) do
          {:ok, json} -> json
          _ -> default
        end

      value ->
        value
    end
  end
end