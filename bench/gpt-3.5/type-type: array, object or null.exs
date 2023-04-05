defmodule :"type: array, object or null-gpt-3.5" do
  def validate(nil) do
    :ok
  end

  def validate([]) do
    :ok
  end

  def validate(map) when is_map(map) do
    :ok
  end

  def validate(_) do
    :error
  end
end