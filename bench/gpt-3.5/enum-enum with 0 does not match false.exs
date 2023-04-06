defmodule :"enum-enum with 0 does not match false-gpt-3.5" do
  def validate([0]) do
    :ok
  end

  def validate(_) do
    :error
  end
end