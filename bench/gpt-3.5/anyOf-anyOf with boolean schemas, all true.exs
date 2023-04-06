defmodule :"anyOf-anyOf with boolean schemas, all true-gpt-3.5" do
  def validate(json) when json in [true, false] do
    :ok
  end

  def validate(_) do
    :error
  end
end