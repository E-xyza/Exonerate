defmodule :"type-type: array or object" do
  def validate(value) when is_list(value) or is_map(value), do: :ok
  def validate(_), do: :error
end
