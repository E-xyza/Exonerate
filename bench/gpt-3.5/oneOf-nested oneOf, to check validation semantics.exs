defmodule :"oneOf-nested oneOf, to check validation semantics-gpt-3.5" do
  def validate(value) when is_map(value) and not Map.is_empty(value) do
    :ok
  end

  def validate(value) when is_nil(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end
