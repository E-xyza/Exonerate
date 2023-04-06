defmodule :"oneOf-oneOf with boolean schemas, one true-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(false) do
    :error
  end

  def validate(_) do
    :error
  end
end