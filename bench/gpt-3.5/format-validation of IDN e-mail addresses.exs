defmodule :"format-validation of IDN e-mail addresses-gpt-3.5" do
  def validate(%{"format" => "idn-email"} = object) do
    case validate_email(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_email(%{"email" => email}) do
    regex = ~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/u
    Regex.match?(regex, email)
  end

  defp validate_email(_) do
    false
  end
end