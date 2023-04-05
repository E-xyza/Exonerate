defmodule :"anyOf with boolean schemas, all false-gpt-3.5" do
  def validate(false) do
    :error
  end

  def validate(_) do
    :ok
  end
end