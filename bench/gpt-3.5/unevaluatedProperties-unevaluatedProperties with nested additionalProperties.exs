defmodule :"unevaluatedProperties-unevaluatedProperties with nested additionalProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object_properties(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object_properties(object) do
    case validate_properties(object) do
      :ok ->
        case validate_additional_properties(object) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_properties(object) do
    case Map.has_key?(object, "foo") do
      true ->
        case validate_property_type(object["foo"], "string") do
          :ok -> :ok
          _ -> :error
        end

      false ->
        :error
    end
  end

  defp validate_property_type(value, "string") when is_binary(value) do
    :ok
  end

  defp validate_property_type(_, _) do
    :error
  end

  defp validate_additional_properties(object) do
    case Map.keys(object) |> Enum.reject(&(&1 == "foo")) do
      [] -> :ok
      _ -> :error
    end
  end
end