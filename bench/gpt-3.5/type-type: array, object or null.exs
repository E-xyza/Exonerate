defmodule :"type-type: array, object or null-gpt-3.5" do
  def validate(nil) do
    :ok
  end

  def validate([]) do
    :ok
  end

  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
