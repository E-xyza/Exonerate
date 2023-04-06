defmodule :"enum-enum with false does not match 0-gpt-3.5" do
  def validate([false]) do
    :ok
  end

  def validate(_) do
    :error
  end
end