defmodule :"const-nul characters in strings" do
  def validate(value) when value == "hello" <> <<0>> <> "there", do: :ok
  def validate(_), do: :error
end
