defmodule :"const-const with {\"a\": true} does not match {\"a\": 1}" do
  def validate(%{"a" => true} = value) when is_map(value), do: :ok
  def validate(_), do: :error
end
