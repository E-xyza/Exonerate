defmodule :"nul characters in strings-gpt-3.5" do
  def validate([<<"hello", 0::utf8, "there">>]) do
    :ok
  end

  def validate(_) do
    :error
  end
end
