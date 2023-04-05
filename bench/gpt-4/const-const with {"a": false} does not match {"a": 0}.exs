defmodule :"const with {\"a\": false} does not match {\"a\": 0}" do
  def validate(%{"a" => false}), do: :ok
  def validate(_), do: :error
end
