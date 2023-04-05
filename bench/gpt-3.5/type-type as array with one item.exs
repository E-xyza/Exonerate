defmodule :"type as array with one item-gpt-3.5" do
  def validate(["string"] = value) do
    :ok
  end

  def validate(_) do
    :error
  end
end