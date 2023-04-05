defmodule :"dependentRequired-single dependency" do
  def validate(map) when is_map(map) and not Map.has_key?(map, "bar"), do: :ok
  def validate(%{"bar" => _, "foo" => _} = map) when is_map(map), do: :ok
  def validate(_), do: :error
end
