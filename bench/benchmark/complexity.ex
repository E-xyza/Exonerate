defmodule Benchmark.Complexity do
  # measures the complexity of a JSON structure (as translated to Elixir)
  # this complexity will simply count how many leaf elements and nodes
  # exist in the structure
  def measure(object) when is_map(object) do
    object
    |> Map.values()
    |> Enum.map(&measure/1)
    |> Enum.sum()
    |> Kernel.+(1)
  end

  def measure(array) when is_list(array) do
    array
    |> Enum.map(&measure/1)
    |> Enum.sum()
    |> Kernel.+(1)
  end

  def measure(_), do: 1
end
