defmodule :"format-validation of URI templates" do
  def validate(uri_template) when is_binary(uri_template) do
    if valid_uri_template?(uri_template) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_uri_template?(uri_template) do
    # Check if uri_template is a valid URI template
    # This is a basic regex for URI template validation and may not cover all edge cases
    uri_template_pattern = ~r/^(?:\{[^\{\}]*\}|[^\{\}])+$/u

    case Regex.match?(uri_template_pattern, uri_template) do
      true -> true
      false -> false
    end
  end
end
