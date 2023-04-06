defmodule :"dependentRequired-empty dependents-gpt-3.5" do
  def validate(object) when is_map(object) do
    check_empty_dependents(object)
  end

  def validate(_) do
    :error
  end

  defp check_empty_dependents(object) do
    case Map.fetch(object, "bar") do
      {:ok, []} -> :ok
      _ -> :error
    end
  end
end