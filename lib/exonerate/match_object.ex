defmodule Exonerate.MatchObject do

  alias Exonerate.BuildCond
  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec match(Parser.t, specmap, boolean) :: Parser.t
  def match(parser, spec, terminal \\ true) do

    # build the conditional statement that guards on the object
    cond_stmt = spec
    |> build_cond(parser.method)
    |> BuildCond.build

    obj_match = quote do
      defp unquote(parser.method)(val) when is_map(val) do
        unquote(cond_stmt)
      end
    end

    parser
    |> Parser.add_dependencies(build_deps(spec, parser.method))
    |> Parser.append_block(obj_match)
    |> Parser.never_matches(terminal)
  end

  @spec build_cond(specmap, atom) :: [BuildCond.condclause]
  #
  # Conditional clauses that don't require any dependencies.
  #
  defp build_cond(spec = %{"minProperties" => min}, method) do
    [{
      quote do
        Enum.count(val) < unquote(min)
      end,
      quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("minProperties")
    |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"maxProperties" => max}, method) do
    [{
      quote do
        Enum.count(val) > unquote(max)
      end,
      quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("maxProperties")
    |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"required" => plist}, method) do
    [{
      quote do
        ! Enum.all?(unquote(plist), &Map.has_key?(val, &1))
      end,
      quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("required")
    |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"propertyNames" => true}, method) do
    # true potentially matches anything, so let's not add any conditionals.
    spec
    |> Map.delete("propertyNames")
    |> build_cond(method)
  end
  defp build_cond(spec = %{"propertyNames" => false}, method) do
    #false matches nothing but empty object, so add a very tight conditional.
    [{
      quote do val != %{} end,
      quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_cond(method)
    ]
  end
  #
  # this conditional is a double match so it needs to be treated specially and
  # in front of the other properties.
  #
  defp build_cond(spec = %{"additionalProperties" => _, "patternProperties" => patts}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end

    regexes = patts
    |> Map.keys
    |> Enum.map(fn v -> quote do sigil_r(<<unquote(v)>>,'') end end)

    child_fn = method
    |> Method.concat("additional_properties")
    |> Method.to_lambda

    [{
      quote do
        parse_additional = Exonerate.Check.object_additional_properties(
                    val,
                    unquote(props),
                    unquote(regexes),
                    unquote(child_fn))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.drop(["additionalProperties"])
    |> build_cond(method))
  end
  #
  # additionalProperties needs to be ahead of properties, because it can gate
  # on that condition.
  #
  defp build_cond(spec = %{"additionalProperties" => _}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end
    child_fn = method
    |> Method.concat("additional_properties")
    |> Method.to_lambda()
    [{
      quote do
        parse_additional = Exonerate.Check.object_additional_properties(
                    val,
                    unquote(props),
                    unquote(child_fn))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalProperties")
    |> build_cond(method))
  end
  #
  # conditional building that has dependencies.
  #
  defp build_cond(spec = %{"dependencies" => dobj}, method) do
    Enum.map(dobj, fn {k, _v} ->
      child_fn = method
      |> Method.concat("dependencies")
      |> Method.concat(k)
      |> Method.to_lambda
      {
        quote do
          parse_prop_dep = Exonerate.Check.object_property_dependency(
            val,
            unquote(k),
            unquote(child_fn)
          )
        end,
        quote do
          parse_prop_dep
        end
      }
    end) ++
    (spec
    |> Map.delete("dependencies")
    |> build_cond(method))
  end
  defp build_cond(spec = %{"properties" => pobj}, method) do
    Enum.map(pobj, fn {k, _v} ->
      child_fn = method
      |> Method.concat("properties")
      |> Method.concat(k)
      |> Method.to_lambda
      {
        quote do
          parse_recurse = Exonerate.Check.object_property(
            val[unquote(k)],
            unquote(child_fn)
            )
          end,
          quote do parse_recurse end
        }
      end) ++
    (spec
    |> Map.delete("properties")
    |> build_cond(method))
  end
  defp build_cond(spec = %{"propertyNames" => _}, method) do
    child_fn = method
    |> Method.concat("property_names")
    |> Method.to_lambda
    [{
      quote do
        parse_properties = Exonerate.Check.object_property_names(
          val,
          unquote(child_fn)
        )
      end,
      quote do parse_properties end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.map(fn {{k, _v}, idx} ->
      child_fn = method
      |> Method.concat("pattern_properties__#{idx}")
      |> Method.to_lambda
      {
        quote do
          parse_pattern_prop = Exonerate.Check.object_pattern_properties(
            val,
            sigil_r(<<unquote(k)>>, ''),
            unquote(child_fn)
          )
        end,
        quote do
          parse_pattern_prop
        end
      }
    end)) ++
    (spec
    |> Map.delete("patternProperties")
    |> build_cond(method))
  end
  defp build_cond(_spec, _method), do: []

  #############################################################################
  ## Dependency building

  @spec build_deps(specmap, atom) :: [Parser.t]
  defp build_deps(spec = %{"properties" => pobj}, method) do
    Enum.map(pobj, fn {k, v} ->
      property_dep({"properties__" <> k, v}, method)
    end) ++
    build_deps(Map.delete(spec, "properties"), method)
  end
  defp build_deps(spec = %{"propertyNames" => pobj}, method) when is_map(pobj) do
    obj_string = Map.put(pobj, "type", "string")
    [ property_dep({"property_names", obj_string}, method)
    | build_deps(Map.delete(spec, "propertyNames"), method)]
  end
  defp build_deps(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.map(fn {{_k, v}, idx} ->
      pattern_property_dep(v, idx, method)
    end)) ++
    build_deps(Map.delete(spec, "patternProperties"), method)
  end
  defp build_deps(spec = %{"additionalProperties" => pobj}, method) do
    [ property_dep({"additional_properties", pobj}, method)
    | build_deps(Map.delete(spec, "additionalProperties"), method)]
  end
  defp build_deps(spec = %{"dependencies" => dobj}, method) do
    object_dep(dobj, method) ++
    build_deps(Map.delete(spec, "dependencies"), method)
  end
  defp build_deps(_, _), do: []

  @spec pattern_property_dep(specmap, non_neg_integer, atom) :: Parser.t
  defp pattern_property_dep(v, idx, method) do
    pattern_child = Method.concat(method, "pattern_properties__#{idx}")
    Parser.new_match(v, pattern_child)
  end

  @spec property_dep({String.t, json}, atom) :: Parser.t
  defp property_dep({k, v}, method) do
    object_child = Method.concat(method, k)
    Parser.new_match(v, object_child)
  end

  @spec object_dep({String.t, json} | json, atom) :: [Parser.t]
  defp object_dep(dobj, method) when is_map dobj do
    Enum.map(dobj, &object_dep(&1, method))
  end
  defp object_dep({k, v}, method) when is_list(v) do
    dep_child = method
    |> Method.concat("dependencies")
    |> Method.concat(k)

    %Parser{
      blocks:
        [quote do
          defp unquote(dep_child)(val) do
            prop_list = unquote(v)
            if Enum.all?(prop_list, &Map.has_key?(val, &1)) do
              :ok
            else
              Exonerate.mismatch(__MODULE__, unquote(dep_child), val)
            end
          end
        end],
      refimp: MapSet.new([dep_child])
    }
  end
  defp object_dep({k, v}, method) when is_map(v) do
    dep_child = method
    |> Method.concat("dependencies")
    |> Method.concat(k)

    v
    |> Map.put("type", "object")
    |> Parser.new_match(dep_child)
  end
  defp object_dep({k, v}, method) do
    dep_child = method
    |> Method.concat("dependencies")
    |> Method.concat(k)

    Parser.new_match(v, dep_child)
  end

end
