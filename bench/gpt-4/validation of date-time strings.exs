defmodule :"validation of date-time strings" do
  def validate(datetime_string) when is_binary(datetime_string) do
    if valid_datetime?(datetime_string) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_datetime?(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, _} -> true
      :error -> false
    end
  end
end
