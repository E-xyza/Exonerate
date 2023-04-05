defmodule :"pattern-pattern validation" do
  def validate(value) when is_binary(value) and Regex.match?(~r/^a*$/, value), do: :ok
  def validate(_), do: :error
end
