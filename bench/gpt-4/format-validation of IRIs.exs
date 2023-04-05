defmodule :"validation of IRIs" do
  def validate(iri) when is_binary(iri) do
    if valid_iri?(iri) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_iri?(iri) do
    # Check if iri is a valid IRI
    # This is a basic regex for IRI validation and may not cover all edge cases
    iri_pattern = ~r/^((?:(?:[^:\/?#]+):)?)(\/\/(?:[^\/?#]*))?([^?#]*)(\?(?:[^#]*))?(#(?:.*))?$/u

    case Regex.match?(iri_pattern, iri) do
      true -> true
      false -> false
    end
  end
end
