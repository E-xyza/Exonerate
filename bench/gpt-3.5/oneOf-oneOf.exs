defmodule :"oneOf-oneOf-gpt-3.5" do
  def validate(value) when is_integer(value) do
    :ok
  end

  def validate(value)
      when is_map(value) and Map.has_key?(value, :minimum) and value[:minimum] >= 2 do
    :ok
  end

  def validate(_) do
    :error
  end
end