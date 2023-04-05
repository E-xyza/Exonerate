defmodule :"uniqueItems=false with an array of items-gpt-3.5" do
  def validate([head | tail]) when is_list(tail) do
    validate([head]) == :ok && validate(tail)
  end

  def validate([head | []]) do
    validate([head])
  end

  def validate([%{"type" => "boolean"} | tail]) do
    validate(tail)
  end

  def validate(%{"uniqueItems" => false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end