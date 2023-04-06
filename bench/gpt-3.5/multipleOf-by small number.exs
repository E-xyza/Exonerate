defmodule :"multipleOf-by small number-gpt-3.5" do
  def validate(value) when is_number(value) and rem(value, 0.0001) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end