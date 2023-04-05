defmodule :"format-validation of time strings" do
  def validate(time_string) when is_binary(time_string) do
    if valid_time?(time_string) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_time?(time_string) do
    # Check if time_string matches the format "HH:mm:ss.SSS" or "HH:mm:ss"
    case Regex.match?(~r/^([0-1][0-9]|[2][0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]{1,3})?$/, time_string) do
      true -> true
      false -> false
    end
  end
end
