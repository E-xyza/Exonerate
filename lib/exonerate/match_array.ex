defmodule Exonerate.MatchArray do

  alias Exonerate.BuildCond
  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec match(Parser.t, specmap, boolean) :: Parser.t
  def match(parser, spec, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(parser.method)
    |> BuildCond.build

    arr_match = quote do
      defp unquote(parser.method)(val) when is_list(val) do
        unquote(cond_stmt)
      end
    end

    parser
    |> Parser.add_dependencies(build_deps(spec, parser.method))
    |> Parser.append_block(arr_match)
    |> Parser.never_matches(terminal)
  end

  @spec build_cond(specmap, atom) :: [BuildCond.condclause]
  defp build_cond(spec = %{"additionalItems" => _props, "items" => parr}, method) when is_list(parr) do
    #this only gets triggered when we have a tuple list.
    child_fn = method
    |> Method.concat("additional_items")
    |> Method.to_lambda

    length = Enum.count(parr)
    [{
      quote do
        parse_additional = Exonerate.Check.array_additional_items(
                    val,
                    unquote(length),
                    unquote(child_fn))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalItems")
    |> build_cond(method))
  end
  defp build_cond(spec = %{"items" => parr}, method) when is_list(parr) do
    for idx <- 0..(Enum.count(parr) - 1) do
      child_fn = method
      |> Method.concat("items__#{idx}")
      |> Method.to_lambda

      {
        quote do
          parse_recurse = Exonerate.Check.array_tuple(
            val,
            unquote(idx),
            unquote(child_fn)
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
    child_fn = method
    |> Method.concat("items")
    |> Method.to_lambda
    [
      {
        quote do
          parse_recurse = Exonerate.Check.array_items(
            val,
            unquote(child_fn)
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
    child_fn = method
    |> Method.concat("contains")
    |> Method.to_lambda
    [
      {
        quote do
          parse_recurse = Exonerate.Check.array_contains_not(
            val,
            unquote(child_fn)
          )
        end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
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

  @spec build_deps(specmap, atom) :: [Parser.t]
  defp build_deps(spec = %{"additionalItems" => props, "items" => _}, method) do
    [ additional_dep(props, method)
    | build_deps(Map.delete(spec, "additionalItems"), method)]
  end
  defp build_deps(spec = %{"items" => iobj}, method) do
    items_dep(iobj, method) ++
    build_deps(Map.delete(spec, "items"), method)
  end
  defp build_deps(spec = %{"contains" => cobj}, method) do
    [ contains_dep(cobj, method)
    | build_deps(Map.delete(spec, "contains"), method)]
  end
  defp build_deps(_,_), do: []

  @spec additional_dep(specmap, atom) :: Parser.t
  defp additional_dep(prop, method) do
    add_method = Method.concat(method, "additional_items")
    Parser.new_match(prop, add_method)
  end

  @spec items_dep([specmap] | specmap, atom) :: [Parser.t]
  defp items_dep(iarr, method) when is_list(iarr) do
    iarr
    |> Enum.with_index
    |> Enum.map(fn {spec, idx} ->
      item_method = Method.concat(method, "items__#{idx}")
      Parser.new_match(spec, item_method)
    end)
  end
  defp items_dep(iobj, method) do
    items_method = Method.concat(method, "items")
    [Parser.new_match(iobj, items_method)]
  end

  @spec contains_dep(specmap, atom) :: Parser.t
  defp contains_dep(cobj, method) do
    contains_method = Method.concat(method, "contains")
    Parser.new_match(cobj, contains_method)
  end

end
