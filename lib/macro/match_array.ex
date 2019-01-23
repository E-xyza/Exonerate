defmodule Exonerate.MatchArray do

  alias Exonerate.BuildCond
  alias Exonerate.Method

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match(specmap, atom, boolean) :: [defblock]
  def match(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the array type
    dependencies = build_deps(spec, method)

    arr_match = quote do
      def unquote(method)(val) when is_list(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [arr_match | Exonerate.never_matches(method)] ++ dependencies
    else
      [arr_match] ++ dependencies
    end
  end

  @spec build_cond(specmap, atom) :: [BuildCond.cond_clauses]
  defp build_cond(spec = %{"additionalItems" => _props, "items" => parr}, method) when is_list(parr) do
    #this only gets triggered when we have a tuple list.
    child = Method.concat(method, "_additional_items")
    length = Enum.count(parr)
    [{
      quote do
        parse_additional = Exonerate.Check.array_additional_items(
                    val,
                    unquote(length),
                    __MODULE__,
                    unquote(child))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalItems")
    |> build_cond(method))
  end
  defp build_cond(spec = %{"items" => parr}, method) when is_list(parr) do
    for idx <- 0..(Enum.count(parr) - 1) do
      child = Method.concat(method, "_item_#{idx}")
      {
        quote do
          parse_recurse = Exonerate.Check.array_tuple(
            val,
            unquote(idx),
            __MODULE__,
            unquote(child)
          )
        end,
        quote do
          parse_recurse
        end
      }
    end
    ++
    (spec
      |> Map.delete("items")
      |> build_cond(method))
  end
  defp build_cond(spec = %{"items" => _pobj}, method) do
    child = Method.concat(method, "_items")
    [
      {
        quote do
          parse_recurse = Exonerate.Check.array_items(
            val,
            __MODULE__,
            unquote(child)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("items")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"contains" => _pobj}, method) do
    child = Method.concat(method, "_contains")
    [
      {
        quote do
          parse_recurse = Exonerate.Check.array_contains(
            val,
            __MODULE__,
            unquote(child)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("contains")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"minItems" => items}, method) do
    [
      {
        quote do Enum.count(val) < unquote(items) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("minItems")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"maxItems" => items}, method) do
    [
      {
        quote do Enum.count(val) > unquote(items) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("maxItems")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"uniqueItems" => true}, method) do
    [
      {
        quote do Exonerate.Check.contains_duplicate?(val) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("uniqueItems")
      |> build_cond(method)
    ]
  end
  defp build_cond(_spec, _method), do: []

  @spec build_deps(specmap, atom) :: [defblock]
  defp build_deps(spec = %{"additionalItems" => props, "items" => parr}, method) when is_list(parr) do
    additional_dep(props, method) ++
    build_deps(Map.delete(spec, "additionalItems"), method)
  end
  defp build_deps(spec = %{"items" => iobj}, method) do
    items_dep(iobj, method) ++
    build_deps(Map.delete(spec, "items"), method)
  end
  defp build_deps(spec = %{"contains" => cobj}, method) do
    contains_dep(cobj, method) ++
    build_deps(Map.delete(spec, "contains"), method)
  end
  defp build_deps(_,_), do: []

  @spec additional_dep(specmap, atom) :: [defblock]
  defp additional_dep(prop, method) do
    add_method = Method.concat(method, "_additional_items")
    Exonerate.matcher(prop, add_method)
  end

  @spec items_dep([specmap] | specmap, atom) :: [defblock]
  defp items_dep(iarr, method) when is_list(iarr) do
    iarr
    |> Enum.with_index
    |> Enum.flat_map(fn {spec, idx} ->
      item_method = Method.concat(method, "_item_#{idx}")
      Exonerate.matcher(spec, item_method)
    end)
  end
  defp items_dep(iobj, method) do
    items_method = Method.concat(method, "_items")
    Exonerate.matcher(iobj, items_method)
  end

  @spec contains_dep(specmap, atom) :: [defblock]
  defp contains_dep(cobj, method) do
    contains_method = Method.concat(method, "_contains")
    Exonerate.matcher(cobj, contains_method)
  end

end
