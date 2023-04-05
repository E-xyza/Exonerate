defmodule :"multipleOf-by small number" do
  def validate(number) when is_float(number) and rem(number, 0.0001) == 0, do: :ok
  def validate(_), do: :error
end
