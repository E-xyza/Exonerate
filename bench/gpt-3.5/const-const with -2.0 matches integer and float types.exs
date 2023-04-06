defmodule :"const-const with -2.0 matches integer and float types-gpt-3.5" do
  def validate(value) when value == -2.0 or value == "-2.0" do
    :ok
  end

  def validate(_) do
    :error
  end
end