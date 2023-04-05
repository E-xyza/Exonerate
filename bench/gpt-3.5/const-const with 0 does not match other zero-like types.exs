defmodule :"const with 0 does not match other zero-like types-gpt-3.5" do
  def validate(%{"const" => 0}) do
    :ok
  end

  def validate(_) do
    :error
  end
end