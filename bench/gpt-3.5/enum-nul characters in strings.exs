defmodule :"enum-nul characters in strings-gpt-3.5" do
  def validate(object) when is_binary(object) and object == "hello\0there" do
    :ok
  end

  def validate(_) do
    :error
  end
end