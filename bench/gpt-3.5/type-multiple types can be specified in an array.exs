defmodule :"multiple types can be specified in an array-gpt-3.5" do
  def validate(value) when value in [integer(), string()] do
    :ok
  end

  def validate(_) do
    :error
  end
end