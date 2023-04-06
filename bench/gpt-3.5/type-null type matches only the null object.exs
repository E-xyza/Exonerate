defmodule :"type-null type matches only the null object-gpt-3.5" do
  def validate(nil) do
    :ok
  end

  def validate(_) do
    :error
  end
end