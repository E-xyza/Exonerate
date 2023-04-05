defmodule :"format-validation of URI references" do
  def validate(uri_ref) when is_binary(uri_ref) do
    if valid_uri_reference?(uri_ref) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_uri_reference?(uri_ref) do
    # Check if uri_ref is a valid URI reference
    # This is a basic regex for URI reference validation and may not cover all edge cases
    uri_ref_pattern = ~r/^((?:(?:[^:\/?#]+):)?)(\/\/(?:[^\/?#]*))?([^?#]*)(\?(?:[^#]*))?(#(?:.*))?$/u

    case Regex.match?(uri_ref_pattern, uri_ref) do
      true -> true
      false -> false
    end
  end
end
