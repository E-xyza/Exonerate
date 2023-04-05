defmodule :"boolean type matches booleans-gpt-3.5" do
  def validate(value) when value === true or value === false do
    :ok
  end

  def validate(_) do
    :error
  end
end