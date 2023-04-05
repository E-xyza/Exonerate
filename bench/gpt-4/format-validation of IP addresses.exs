defmodule :"validation of IP addresses" do
  def validate(ipv4) when is_binary(ipv4) do
    case :inet.parse_address(ipv4) do
      {:ok, _} -> :ok
      {:error, :einval} -> :error
    end
  end

  def validate(_), do: :error
end
