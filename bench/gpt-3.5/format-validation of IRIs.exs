defmodule :"format-validation of IRIs-gpt-3.5" do
  def validate(iri) when is_binary(iri) and Regex.match?(~r{^[a-zA-Z][a-zA-Z0-9+.-]*://}, iri) do
    :ok
  end

  def validate(_) do
    :error
  end
end