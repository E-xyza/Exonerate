defmodule :"minContains = 0-gpt-3.5" do
  def validate(object) when is_map(object) and contains_one(object, 1) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp contains_one(object, value) do
    min_contains = object[:minContains] || 0
    Enum.count(object[:contains], &(&1 === value)) >= min_contains
  end
end