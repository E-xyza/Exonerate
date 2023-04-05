defmodule :"const validation-gpt-3.5" do
  def validate(2) do
    :ok
  end

  def validate(_) do
    :error
  end
end