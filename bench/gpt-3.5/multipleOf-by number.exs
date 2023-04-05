defmodule :"by number-gpt-3.5" do
  def validate(object) when is_float(object) and rem(object, 1.5) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end