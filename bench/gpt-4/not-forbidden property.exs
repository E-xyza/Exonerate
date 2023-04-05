defmodule :"not-forbidden property" do
  def validate(object) when not is_map_key(object, "foo"), do: :ok
  def validate(_), do: :error

  defp is_map_key(map, key) do
    is_map(map) and map[key] != nil
  end
end
