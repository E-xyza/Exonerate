defmodule :"nested anyOf, to check validation semantics-gpt-3.5" do
  def validate(object) when object == nil do
    :ok
  end

  def validate(_) do
    :error
  end
end
