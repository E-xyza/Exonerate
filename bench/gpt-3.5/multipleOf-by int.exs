defmodule :"multipleOf-by int-gpt-3.5" do
  def validate(value) when is_integer(value) and rem(value, 2) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end