defmodule :"minProperties validation" do
  def validate(object) when is_map(object) and map_size(object) >= 1, do: :ok
  def validate(_), do: :error
end
