defmodule :"validation of IPv6 addresses-gpt-3.5" do
  def validate(value) do
    case value do
      %{"format" => "ipv6"} ->
        if is_binary(value) and :inet.parse_ipv6(value) do
          :ok
        else
          :error
        end

      _ ->
        :ok
    end
  end
end