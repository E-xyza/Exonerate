defmodule Exonerate.Tools do
  defguard is_member(mapset, element) when
    is_map_key(:erlang.map_get(:map, mapset), element)
end
