defmodule :"maxContains = minContains-gpt-3.5" do
  def validate(arr)
      when is_list(arr) and length(arr) >= @minContains and
             length(Enum.filter(arr, &(&1 == 1))) <= @maxContains do
    :ok
  end

  def validate(_) do
    :error
  end

  @impl true
  def init([]) do
    []
  end

  def init(config) do
    config
    |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, to_atom(k), v) end)
    |> Map.merge(%{minContains: 0, maxContains: 100})
  end
end