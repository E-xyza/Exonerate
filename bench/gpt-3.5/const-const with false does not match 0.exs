defmodule :"const-const with false does not match 0-gpt-3.5" do
  def validate(false) do
    :error
  end

  def validate(_) do
    :ok
  end
end