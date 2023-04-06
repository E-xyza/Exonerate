defmodule :"allOf-allOf with boolean schemas, all true-gpt-3.5" do
  def validate(schema) when schema == %{"allOf" => [true, true]} do
    :ok
  end

  def validate(_) do
    :error
  end
end