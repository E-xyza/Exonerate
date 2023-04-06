defmodule :"format-validation of URIs-gpt-3.5" do
  def validate(object) when is_map(object) and is_valid_uri?(Map.get(object, "uri")) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_valid_uri?(uri) do
    case URI.parse(uri) do
      {:error, _} -> false
      _ -> true
    end
  end
end