defmodule :"type-multiple types can be specified in an array-gpt-3.5" do
  def validate(value) when is_integer(value) or is_binary(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end