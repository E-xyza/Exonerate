defmodule :"enum-enum with true does not match 1-gpt-3.5" do
  def validate([true]) do
    :ok
  end

  def validate(_) do
    :error
  end
end