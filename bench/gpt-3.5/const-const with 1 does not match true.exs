defmodule :"const with 1 does not match true-gpt-3.5" do
  def validate(const_value) when const_value === 1 do
    :ok
  end

  def validate(_) do
    :error
  end
end