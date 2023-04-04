defmodule :"validation of IPv6 addresses" do
  def validate(ipv6) when is_binary(ipv6) do
    case :inet.parse_address(ipv6, :inet6) do
      {:ok, _} -> :ok
      {:error, :einval} -> :error
    end
  end

  def validate(_), do: :error
end
