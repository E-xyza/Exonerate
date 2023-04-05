defmodule :"allOf simple types-gpt-3.5" do
  def validate(json) when is_integer(json) and json <= 30 and json >= 20 do
    :ok
  end

  def validate(_) do
    :error
  end
end