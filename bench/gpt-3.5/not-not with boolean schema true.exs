defmodule :"not-not with boolean schema true-gpt-3.5" do
  def validate(true) do
    :error
  end

  def validate(_) do
    :ok
  end
end