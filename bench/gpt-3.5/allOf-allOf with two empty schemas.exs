defmodule :"allOf-allOf with two empty schemas-gpt-3.5" do
  def validate(%{} = object) do
    :ok
  end

  def validate(_) do
    :error
  end
end