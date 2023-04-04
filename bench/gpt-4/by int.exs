defmodule :"by int" do
  def validate(value) when is_integer(value) and rem(value, 2) == 0, do: :ok
  def validate(_), do: :error
end
