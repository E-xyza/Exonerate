defmodule :"multipleOf-by number" do
  def validate(object) when is_float(object) and rem(object, 1.5) == 0, do: :ok
  def validate(object) when is_integer(object) and rem(object, 3) == 0, do: :ok
  def validate(_), do: :error
end
