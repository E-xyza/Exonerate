defmodule :"not-not" do
  def validate(object) when is_integer(object), do: :error
  def validate(_), do: :ok
end
