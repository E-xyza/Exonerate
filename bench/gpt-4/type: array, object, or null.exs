defmodule :"type: array, object or null" do
  def validate(value) when is_list(value) or is_map(value) or is_nil(value), do: :ok
  def validate(_), do: :error
end
