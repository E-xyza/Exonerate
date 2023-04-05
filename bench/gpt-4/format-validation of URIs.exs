defmodule :"format-validation of URIs" do
  require URI

  def validate(value) when is_binary(value) and is_valid_uri(value), do: :ok
  def validate(_), do: :error

  defp is_valid_uri(value) do
    case URI.parse(value) do
      %URI{scheme: nil, authority: nil, path: nil, query: nil, fragment: nil} -> false
      _ -> true
    end
  end
end
