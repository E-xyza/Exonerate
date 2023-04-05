defmodule :"const with {\"a\": false} does not match {\"a\": 0}-gpt-3.5" do
  def validate(%{"a" => false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end