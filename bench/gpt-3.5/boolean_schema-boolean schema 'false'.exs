defmodule :"boolean schema 'false'" do
  
defmodule JsonSchema do
  def validate(false), do: :error
  def validate(schema) when is_map(schema) do
    case schema["type"] do
      "object" -> &validate_object/1
      "array" -> &validate_array/1
      "string" -> &validate_string/1
      "integer" -> &validate_integer/1
      "number" -> &validate_number/1
      "boolean" -> &validate_boolean/1
      _ -> &validate_any/1
    end.(schema)
  end
  
  defp validate_object(object_schema) do
    fn object ->
      is_map(object) && Enum.all?(object_schema["properties"], fn {key, sub_schema} -> 
        is_map(object[key]) && validate(sub_schema) == :ok
      end) && Enum.all?(object, fn {key, _} -> 
        Enum.member?(Enum.map(object_schema["properties"], &elem(&1, 0)), key)
      end) && (object_schema["required"] == nil || Enum.all?(object_schema["required"], &Map.has_key?(object, &1)))
    end
  end
  
  defp validate_array(array_schema) do
    fn array ->
      is_list(array) && Enum.all?(array, &validate(&1) == :ok) && (array_schema["minItems"] == nil || length(array) >= array_schema["minItems"]) && (array_schema["maxItems"] == nil || length(array) <= array_schema["maxItems"])
    end
  end
  
  defp validate_string(_), do: &is_binary/1
  
  defp validate_integer(_), do: &is_integer/1
  
  defp validate_number(_), do: &is_number/1
  
  defp validate_boolean(_), do: &is_boolean/1
  
  defp validate_any(_), do: &is_any/1
  
  defp is_boolean(value), do: value === true || value === false
  
  defp is_any(_), do: true
end

end
