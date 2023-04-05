defmodule :"validation of e-mail addresses-gpt-3.5" do
  def validate(email)
      when is_binary(email) and
             Regex.match?(~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, email) do
    :ok
  end

  def validate(_) do
    :error
  end
end