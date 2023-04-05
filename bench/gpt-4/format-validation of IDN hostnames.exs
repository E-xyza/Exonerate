defmodule :"format-validation of IDN hostnames" do
  alias :idna, as: Idna

  def validate(hostname) when is_binary(hostname) do
    if valid_idn_hostname?(hostname) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_idn_hostname?(hostname) do
    case Idna.to_ascii(hostname) do
      {:ok, ascii_hostname} -> valid_ascii_hostname?(ascii_hostname)
      _ -> false
    end
  end

  defp valid_ascii_hostname?(hostname) do
    :inet.parse_strict_address(hostname) == :error and
      Enum.all?(String.split(hostname, ".", trim: true), &valid_label?/1)
  end

  defp valid_label?(label) do
    byte_size(label) in 1..63 and
      String.match?(label, ~r/^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$/)
  end
end
