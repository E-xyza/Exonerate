defmodule :"cousin unevaluatedProperties, true and false, false with properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{} = object) do
    case validate_properties(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  defp validate_object(_) do
    :error
  end

  defp validate_properties(object) do
    case Keyword.get(object, "properties", nil) do
      %{} = properties ->
        case Enum.all?(Map.keys(properties), fn key ->
               validate_property(key, Map.get(properties, key), object)
             end) do
          true -> :ok
          _ -> :error
        end

      _ ->
        :ok
    end
  end

  defp validate_property(key, %{"type" => type}, object) do
    case Map.get(object, key, :missing) do
      :missing -> false
      _ -> is_type(type, Map.get(object, key))
    end
  end

  defp validate_property(_, _, _) do
    true
  end

  defp is_type("string", value) when is_binary(value) do
    true
  end

  defp is_type("number", value) when is_number(value) do
    true
  end

  defp is_type("object", value) when is_map(value) do
    true
  end

  defp is_type(_, _) do
    false
  end
end
