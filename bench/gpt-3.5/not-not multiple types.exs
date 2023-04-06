defmodule :"not-not multiple types-gpt-3.5" do
  def validate(object) when is_integer(object) or is_boolean(object) do
    :error
  end

  def validate(_) do
    :ok
  end
end