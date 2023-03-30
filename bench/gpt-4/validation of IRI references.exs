defmodule :"validation of IRI references" do
  def validate(iri_reference) when is_binary(iri_reference) do
    if valid_iri_reference?(iri_reference) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_iri_reference?(iri_reference) do
    # Check if iri_reference is a valid IRI reference
    # This is a basic regex for IRI reference validation and may not cover all edge cases
    iri_ref_pattern = ~r/^((?:(?:[^:\/?#]+):)?)(\/\/(?:[^\/?#]*))?([^?#]*)(\?(?:[^#]*))?(#(?:.*))?$/u

    case Regex.match?(iri_ref_pattern, iri_reference) do
      true -> true
      false -> false
    end
  end
end
