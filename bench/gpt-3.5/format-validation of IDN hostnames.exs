defmodule :"validation of IDN hostnames-gpt-3.5" do
  def validate(object) when is_binary(object) and is_valid_idn_hostname?(object) do
    :ok
  end

  def validate(object) do
    :error
  end

  defp is_valid_idn_hostname?(hostname) do
    case :inet_parse.idn_to_ascii(hostname) do
      {:ok, _} -> true
      :error -> false
    end
  end
end