defmodule :"allOf-allOf with base schema-gpt-3.5" do
  def validate(data) when is_map(data) do
    case validate_object(data) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "bar") and is_integer(Map.get(object, "bar")) do
      true -> validate_array(object)
      false -> :error
    end
  end

  defp validate_array(array) do
    case Enum.all?(array, fn {key, value} ->
           case key do
             "foo" -> Map.has_key?(array, "foo") and is_string(Map.get(array, "foo"))
             "baz" -> Map.has_key?(array, "baz") and is_nil(Map.get(array, "baz"))
             _ -> false
           end
         end) do
      true -> :ok
      _ -> :error
    end
  end
end
