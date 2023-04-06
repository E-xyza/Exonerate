defmodule :"const-const with null-gpt-3.5" do
  def validate(nil) do
    :ok
  end

  def validate(_) do
    :error
  end
end