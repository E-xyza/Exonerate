defmodule :"validation of IRI references-gpt-3.5" do
  def validate(object) when is_binary(object) and Regex.match?(~r{^https?://}, object) do
    :ok
  end

  def validate(_) do
    :error
  end
end