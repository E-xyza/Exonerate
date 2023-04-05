defmodule :"validation of IP addresses-gpt-3.5" do
  def validate(object) when is_bitstring(object) do
    case :inet_parse.ntoa(object) do
      {_, [], [], _} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end