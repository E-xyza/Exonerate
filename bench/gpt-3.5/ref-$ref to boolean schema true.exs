defmodule :"$ref to boolean schema true-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(_) do
    :error
  end
end