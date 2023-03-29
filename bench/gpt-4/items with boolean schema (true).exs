defmodule :"items with boolean schema (true)" do
  def validate(value) when is_list(value), do: :ok
  def validate(_), do: :error
end
