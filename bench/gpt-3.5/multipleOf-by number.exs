defmodule :"multipleOf-by number-gpt-3.5" do
  def validate(val) when is_number(val) and rem(val, 1.5) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end