defmodule :"anyOf-anyOf with boolean schemas, some true-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(false) do
    :ok
  end

  def validate(_) do
    :error
  end
end
