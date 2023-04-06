defmodule :"unevaluatedProperties-unevaluatedProperties with if/then/else-gpt-3.5" do
  def validate(
        %{
          "unevaluatedProperties" => false,
          "type" => "object",
          "if" => if_schema,
          "then" => then_schema,
          "else" => else_schema
        } = object
      )
      when is_map(object) do
    if_result =
      if if_schema && match_schema(if_schema, object) do
        :ok
      else
        :error
      end

    if if_result == :ok do
      if then_schema && match_schema(then_schema, object) do
        :ok
      else
        :error
      end
    else
      if else_schema && match_schema(else_schema, object) do
        :ok
      else
        :error
      end
    end
  end

  def validate(_) do
    :error
  end

  defp match_schema(schema, object) do
    Enum.all?(schema["required"], fn key ->
      (map =
         Map.take(
           object,
           [key]
         )) == map && validate_type(schema["properties"][key], map[key])
    end)
  end

  defp validate_type(nil, _) do
    true
  end

  defp validate_type(%{"type" => "string"}, value) do
    is_binary(value)
  end

  defp validate_type(%{"type" => "number"}, value) do
    is_number(value)
  end

  defp validate_type(%{"type" => "integer"}, value) do
    is_integer(value)
  end

  defp validate_type(%{"type" => "boolean"}, value) do
    is_boolean(value)
  end

  defp validate_type(%{"type" => "null"}, value) do
    is_nil(value)
  end

  defp validate_type(%{"type" => "array", "items" => items_schema}, value) do
    is_list(value) &&
      Enum.all?(value, fn item -> is_map(item) && match_schema(items_schema, item) end)
  end

  defp validate_type(%{"type" => "object"}, value) do
    is_map(value)
  end

  defp validate_type(%{"const" => const_value}, value) do
    value == const_value
  end

  defp validate_type(_schema, _value) do
    false
  end
end