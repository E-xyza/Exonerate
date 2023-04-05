defmodule :"maxContains with contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_contains(object) do
      :error -> :error
      _ -> validate_max_contains(object)
    end
  end

  def validate(_) do
    :error
  end

  defp validate_contains(object) do
    case Map.get(object, "contains") do
      %{"const" => 1} -> :ok
      _ -> :error
    end
  end

  defp validate_max_contains(object) do
    case Map.get(object, "maxContains") || 0 do
      1 -> :ok
      _ -> :error
    end
  end
end