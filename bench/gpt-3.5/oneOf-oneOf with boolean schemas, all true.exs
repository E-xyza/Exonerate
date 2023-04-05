defmodule :"oneOf with boolean schemas, all true-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(_) do
    :error
  end
end