defmodule :"const-const with {\"a\": false} does not match {\"a\": 0}" do
  def validate(%{"a" => false} = value) when is_map(value), do: :ok
  def validate(_), do: :error
end
