defmodule :"format-validation of e-mail addresses-gpt-3.5" do
  def validate(object) when is_map(object) and is_valid_email(object["email"]) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_valid_email(email) do
    Regex.match?(~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, email)
  end
end