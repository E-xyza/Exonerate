defmodule :"maxProperties-maxProperties validation" do
  def validate(object) when is_map(object) and map_size(object) <= 2, do: :ok
  def validate(_), do: :error
end
