defmodule :"validation of date strings-gpt-3.5" do
  def validate(value) when is_map(value) do
    map_validate(value)
  end

  def validate(_) do
    :error
  end

  defp map_validate(value) do
    if Map.get(value, "__schema__") == "date" do
      case Map.get(value, "__value__") do
        date when is_binary(date) and is_date(date) -> :ok
        _ -> :error
      end
    else
      map_each(value, &validate/1)
    end
  end

  defp map_each(map, fun) do
    Enum.reduce(map, :ok, fn {k, v}, acc ->
      case fun.(v) do
        :error -> :error
        _ -> acc
      end
    end)
  end

  defp is_date(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> true
      _ -> false
    end
  end
end