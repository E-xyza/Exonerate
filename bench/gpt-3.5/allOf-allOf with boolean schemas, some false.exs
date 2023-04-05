defmodule :"allOf with boolean schemas, some false-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(_) do
    :error
  end
end