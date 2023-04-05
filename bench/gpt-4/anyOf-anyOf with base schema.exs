defmodule :"anyOf-anyOf with base schema" do
  def validate(value) when is_binary(value) and (String.length(value) <= 2 or String.length(value) >= 4), do: :ok
  def validate(_), do: :error
end
