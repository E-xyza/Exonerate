defmodule Exonerate.Combining do
  @modules %{
    "anyOf" => Exonerate.Combining.AnyOf,
    "allOf" => Exonerate.Combining.AllOf,
    "oneOf" => Exonerate.Combining.OneOf,
    "not" => Exonerate.Combining.Not,
    "$ref" => Exonerate.Combining.Ref,
    "if" => Exonerate.Combining.If
  }

  @filters Map.keys(@modules)

  def merge(map), do: Map.merge(map, @modules)

  def modules, do: @modules

  def filters, do: @filters

  def filter?(filter), do: is_map_key(@modules, filter)

  def adjust(filter_name, tracked \\ false)

  def adjust("not", _), do: ["not", ":entrypoint"]
  def adjust(filter, true), do: adjust(filter, false) ++ [":tracked"]
  def adjust("if", _), do: ["if", ":entrypoint"]
  def adjust(other, _), do: [other]

  # code helpers

  def or_ok(tracked, quoted) do
    if tracked do
      quoted
    else
      :ok
    end
  end

  defmacro initialize(tracked) do
    or_ok(
      tracked,
      quote do
        {:ok, MapSet.new()}
      end
    )
  end

  defmacro capture(tracked, visited) do
    or_ok(
      tracked,
      quote do
        {:ok, unquote(visited)}
      end
    )
  end

  defmacro update_key(tracked, visited, key) do
    or_ok(
      tracked,
      quote do
        {:ok, MapSet.put(unquote(visited), unquote(key))}
      end
    )
  end

  defmacro update_set(tracked, visited, set) do
    or_ok(
      tracked,
      quote do
        {:ok, MapSet.union(unquote(visited), unquote(set))}
      end
    )
  end
end
