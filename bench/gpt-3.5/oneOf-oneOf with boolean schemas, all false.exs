defmodule :"oneOf with boolean schemas, all false-gpt-3.5" do
  def validate([false, false, false]) do
    :ok
  end

  def validate(_) do
    :error
  end
end