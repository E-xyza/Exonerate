defmodule :"items with boolean schema (false)" do
  def validate(value) when is_list(value) and length(value) == 0, do: :ok
  def validate(_), do: :error
end
