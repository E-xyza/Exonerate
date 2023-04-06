defmodule :"minContains-minContains=2 with contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_contains(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_contains(object) do
    case Map.get(object, "contains") do
      nil ->
        true

      const ->
        case Map.get(object, "minContains") do
          nil ->
            true

          min_cont ->
            object
            |> Map.delete("contains")
            |> Map.delete("minContains")
            |> Map.values()
            |> Enum.count(const) >= min_cont
        end
    end
  end
end