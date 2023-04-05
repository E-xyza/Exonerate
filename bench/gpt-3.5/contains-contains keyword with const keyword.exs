defmodule :"contains keyword with const keyword-gpt-3.5" do
  def validate(object) when is_map(object) and map_contains_const?(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp map_contains_const?(map) do
    case map[:contains] do
      nil -> false
      instruction -> contains_const?(instruction, map)
    end
  end

  defp contains_const?({:const, value}, map) do
    map_contains_value?(map, value)
  end

  defp map_contains_value?(map, value) do
    Enum.any?(map, fn {_key, val} -> val === value end)
  end
end