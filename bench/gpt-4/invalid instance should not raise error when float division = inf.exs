defmodule :"invalid instance should not raise error when float division = inf" do
  def validate(integer) when is_integer(integer), do: :ok
  def validate(float) when is_float(float) and div(float, 0.123456789) == :math.inf, do: :ok
  def validate(_), do: :error
end
