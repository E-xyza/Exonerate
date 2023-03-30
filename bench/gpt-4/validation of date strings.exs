defmodule :"validation of date strings" do
  def validate(date_string) when is_binary(date_string) do
    if valid_date?(date_string) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_date?(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, _} -> true
      :error -> false
    end
  end
end
