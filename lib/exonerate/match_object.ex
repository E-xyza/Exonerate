defmodule Exonerate.MatchObject do

  alias Exonerate.BuildCond
  alias Exonerate.Method

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match(specmap, atom, boolean) :: [defblock]
  def match(spec, method, terminal \\ true) do

    # build the conditional statement that guards on the object
    cond_stmt = spec
    |> build_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the object type
    dependencies = build_deps(spec, method)

    obj_match = quote do
      def unquote(method)(val) when is_map(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [obj_match | Exonerate.never_matches(method)] ++ dependencies
    else
      [obj_match] ++ dependencies
    end
  end

  @spec build_cond(specmap, atom) :: [BuildCond.cond_clauses]
  defp build_cond(spec = %{"additionalProperties" => _, "patternProperties" => patts}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end

    regexes = patts
    |> Map.keys
    |> Enum.map(fn v -> quote do sigil_r(<<unquote(v)>>,'') end end)

    child = Method.concat(method, "_additional_properties")

    [{
      quote do
        parse_additional = Exonerate.Check.object_additional_properties(
                    val,
                    unquote(props),
                    unquote(regexes),
                    __MODULE__,
                    unquote(child))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.drop(["additionalProperties"])
    |> build_cond(method))
  end
  defp build_cond(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.map(fn {{k, _v}, idx} ->
      child = Method.concat(method, "_pattern_#{idx}")
      {
        quote do
          parse_pattern_prop = Exonerate.Check.object_pattern_properties(
            val,
            sigil_r(<<unquote(k)>>, ''),
            __MODULE__,
            unquote(child)
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
  defp build_cond(spec = %{"dependencies" => dobj}, method) do
    Enum.map(dobj, fn {k, _v} ->
      child = Method.concat(method, "_dependency_" <> k)
      {
        quote do
          parse_prop_dep = Exonerate.Check.object_property_dependency(
            val,
            unquote(k),
            __MODULE__,
            unquote(child)
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
  defp build_cond(spec = %{"propertyNames" => _}, method) do
    child = Method.concat(method, "_property_names")
    [{
      quote do
        parse_properties = Exonerate.Check.object_property_names(
          val,
          __MODULE__,
          unquote(child)
        )
      end,
      quote do parse_properties end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"additionalProperties" => _}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end
    child = Method.concat(method, "_additional_properties")
    [{
      quote do
        parse_additional = Exonerate.Check.object_additional_properties(
                    val,
                    unquote(props),
                    __MODULE__,
                    unquote(child))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalProperties")
    |> build_cond(method))
  end
  defp build_cond(spec = %{"properties" => pobj}, method) do
    Enum.map(pobj, fn {k, _v} ->
      child = Method.concat(method, k)
      {
        quote do
          parse_recurse = Exonerate.Check.object_property(
            val[unquote(k)],
            __MODULE__,
            unquote(child)
          )
        end,
        quote do parse_recurse end
      }
    end) ++
    (spec
    |> Map.delete("properties")
    |> build_cond(method))
  end
  defp build_cond(_spec, _method), do: []

  #############################################################################
  ## Dependency building

  @spec build_deps(specmap, atom) :: [defblock]
  defp build_deps(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.flat_map(fn {{_k, v}, idx} ->
      pattern_property_dep(v, idx, method)
    end)) ++
    build_deps(Map.delete(spec, "patternProperties"), method)
  end
  defp build_deps(spec = %{"properties" => pobj}, method) do
    Enum.flat_map(pobj, &property_dep(&1, method)) ++
    build_deps(Map.delete(spec, "properties"), method)
  end
  defp build_deps(spec = %{"propertyNames" => pobj}, method) when is_map(pobj) do
    obj_string = Map.put(pobj, "type", "string")
    property_dep({"_property_names", obj_string}, method) ++
    build_deps(Map.delete(spec, "propertyNames"), method)
  end
  defp build_deps(spec = %{"additionalProperties" => pobj}, method) do
    property_dep({"_additional_properties", pobj}, method) ++
    build_deps(Map.delete(spec, "additionalProperties"), method)
  end
  defp build_deps(spec = %{"dependencies" => dobj}, method) do
    object_dep(dobj, method) ++
    build_deps(Map.delete(spec, "dependencies"), method)
  end
  defp build_deps(_, _), do: []

  @spec pattern_property_dep(specmap, non_neg_integer, atom) :: [defblock]
  defp pattern_property_dep(v, idx, method) do
    pattern_child = Method.concat(method, "_pattern_#{idx}")
    Exonerate.matcher(v, pattern_child)
  end

  @spec property_dep({String.t, json}, atom) :: [defblock]
  defp property_dep({k, v}, method) do
    object_child = Method.concat(method, k)
    Exonerate.matcher(v, object_child)
  end

  @spec object_dep({String.t, json} | json, atom) :: [defblock]
  defp object_dep(dobj, method) when is_map dobj do
    Enum.flat_map(dobj, &object_dep(&1, method))
  end
  defp object_dep({k, v}, method) when is_list(v) do
    dep_child = Method.concat(method, "_dependency_" <> k)
    [quote do
      def unquote(dep_child)(val) do
        prop_list = unquote(v)
        if Enum.all?(prop_list, &Map.has_key?(val, &1)) do
          :ok
        else
          Exonerate.mismatch(__MODULE__, unquote(dep_child), val)
        end
      end
    end]
  end
  defp object_dep({k, v}, method) when is_map(v) do
    dep_child = Method.concat(method, "_dependency_" <> k)
    v
    |> Map.put("type", "object")
    |> Exonerate.matcher(dep_child)
  end
  defp object_dep({k, v}, method) do
    dep_child = Method.concat(method, "_dependency_" <> k)
    Exonerate.matcher(v, dep_child)
  end

end
