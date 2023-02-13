defmodule Exonerate.Combining do
  @combiners %{
    "anyOf" => Exonerate.Combining.AnyOf
  }

  def merge(map), do: Map.merge(map, @combiners)

  def filters, do: @combiners

  def filter?(filter), do: is_map_key(@combiners, filter)
end
