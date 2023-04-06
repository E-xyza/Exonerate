defmodule :"format-validation of IRI references-gpt-3.5" do
  def validate(value) do
    case value do
      %{"$ref" => _} -> :ok
      %{"format" => "iri-reference"} -> :ok
      _ -> :error
    end
  end
end