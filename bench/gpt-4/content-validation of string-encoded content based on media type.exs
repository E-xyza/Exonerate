defmodule :"content-validation of string-encoded content based on media type" do
  def validate(input) when is_binary(input) do
    case decode_json(input) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end
  def validate(_), do: :error

  defp decode_json(input) do
    try do
      {:ok, Jason.decode!(input)}
    rescue
      Jason.DecodeError ->
        :error
    end
  end
end
