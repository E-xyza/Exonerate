defmodule :"const with {\"a\": true} does not match {\"a\": 1}" do
  def validate(%{"a" => true}), do: :ok
  def validate(_), do: :error
end
