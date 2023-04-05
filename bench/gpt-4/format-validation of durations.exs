defmodule :"format-validation of durations" do
  def validate(duration) when is_binary(duration) do
    if valid_duration?(duration) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_duration?(duration) do
    # Check if duration is a valid ISO 8601 duration
    duration_pattern = ~r/\A(?:P(?:-?\d+(?:\.\d+)?Y)?(?:-?\d+(?:\.\d+)?M)?(?:-?\d+(?:\.\d+)?W)?(?:-?\d+(?:\.\d+)?D)?(?:T(?:-?\d+(?:\.\d+)?H)?(?:-?\d+(?:\.\d+)?M)?(?:-?\d+(?:\.\d+)?S)?)?|PT0S)\z/u

    case Regex.match?(duration_pattern, duration) do
      true -> true
      false -> false
    end
  end
end
