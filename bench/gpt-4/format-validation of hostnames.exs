defmodule :"format-validation of hostnames" do
  def validate(hostname) when is_binary(hostname) do
    if valid_hostname?(hostname) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_hostname?(hostname) do
    :inet.parse_strict_address(hostname) == :error and
      Enum.all?(String.split(hostname, ".", trim: true), &valid_label?/1)
  end

  defp valid_label?(label) do
    byte_size(label) in 1..63 and
      String.match?(label, ~r/^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$/)
  end
end
