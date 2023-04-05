defmodule :"oneOf-gpt-3.5" do
  def validate(value) when is_integer(value) do
    :ok
  end

  def validate(value) when is_map(value) and map_size(value) > 1 do
    :ok
  end

  def validate(_) do
    :error
  end
end