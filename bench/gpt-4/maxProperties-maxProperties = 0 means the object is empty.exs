defmodule :"maxProperties-maxProperties = 0 means the object is empty" do
  def validate(object) when is_map(object) and map_size(object) == 0, do: :ok
  def validate(_), do: :error
end
