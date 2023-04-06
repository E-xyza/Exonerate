defmodule :"unevaluatedProperties-unevaluatedProperties with not-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) when is_map(object) do
    case Map.has_key?(object, "foo") do
      true ->
        case Map.get(object, "foo") do
          s when is_binary(s) -> :ok
          _ -> :error
        end

      _ ->
        :ok
    end
  end

  defp validate_object(_) do
    :error
  end
end
