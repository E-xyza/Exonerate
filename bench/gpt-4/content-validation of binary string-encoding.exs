defmodule :"content-validation of binary string-encoding" do
  def validate(input) when is_binary(input) do
    case decode_base64(input) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end
  def validate(_), do: :error

  defp decode_base64(input) do
    case Base.decode64(input) do
      {:ok, _} -> :ok
      :error -> :error
    end
  end
end
