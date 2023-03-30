defmodule :"nul characters in strings" do
  def validate("hello" <> <<0>> <> "there"), do: :ok
  def validate(_), do: :error
end
