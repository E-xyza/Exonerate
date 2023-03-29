defmodule :"validation of date strings-gpt-3.5" do
  def validate(%{"format" => "date"} = object) when is_map(object) and is_date(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_date(object) do
    case Date.from_iso8601(Map.get(object, "date")) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
