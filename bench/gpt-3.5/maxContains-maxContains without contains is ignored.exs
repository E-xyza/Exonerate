defmodule :"maxContains-maxContains without contains is ignored-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.size(object) do
      1 -> validate_max_contains(object)
      _ -> :ok
    end
  end

  def validate(_) do
    :error
  end

  defp validate_max_contains(object) do
    case Map.fetch!(object, "maxContains", nil) do
      1 -> :ok
      _ -> :error
    end
  end
end
