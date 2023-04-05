defmodule :"by int-gpt-3.5" do
  def validate(json) when is_integer(json) and rem(json, 2) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end