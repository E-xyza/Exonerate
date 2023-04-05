defmodule :"type: array or object-gpt-3.5" do
  def validate([]) do
    :ok
  end

  def validate(%{}) do
    :ok
  end

  def validate(_) do
    :error
  end
end