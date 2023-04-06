defmodule :"anyOf-anyOf with boolean schemas, all false-gpt-3.5" do
  def validate(false) do
    :ok
  end

  def validate(_) do
    :error
  end
end