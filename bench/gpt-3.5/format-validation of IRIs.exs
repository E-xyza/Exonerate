defmodule :"validation of IRIs-gpt-3.5" do
  def validate(iri) when is_binary(iri) and Regex.match?(~r/^[a-z][a-z\d+.-]*:/i, iri) do
    :ok
  end

  def validate(_) do
    :error
  end
end