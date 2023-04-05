defmodule :"nul characters in strings-gpt-3.5" do
  def validate(%{"const" => "hello\0there"} = _object) do
    :ok
  end

  def validate(_) do
    :error
  end
end