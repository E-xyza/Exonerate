defmodule :"additionalProperties should not look in applicators-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object) do
      :ok ->
        case Map.get(object, :foo) do
          nil -> :ok
          value -> validate(value)
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(object) do
    case Map.keys(object) -- [:foo] do
      [] -> :ok
      _ -> :error
    end
  end
end