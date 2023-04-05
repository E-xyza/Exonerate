defmodule :"validation of URIs-gpt-3.5" do
  def validate(object) when is_map(object) and is_uri(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_uri(object) do
    case URI.parse(object) do
      %URI{} -> true
      _ -> false
    end
  end
end