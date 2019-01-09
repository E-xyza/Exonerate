defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Macro.BuildCond

  @type condlist :: [BuildCond.condclause]
  @type defblock :: {:def, any, any}

  defmacro defschema([{method, json} | _opts]) do

    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    code2 = quote do
      unquote_splicing(code)
    end

    # TODO:
    # remove this block.  It's only for checking it out.

    IO.puts("")
    code2
    |> Macro.to_string
    |> Code.format_string!
    |> Enum.join
    |> IO.puts

    code2
  end

  @spec matcher(any, any)::[defblock | {:__block__, any, any}]
  def matcher(map, method) when map == %{}, do: [always_matches(method)]
  def matcher(true, method), do: [always_matches(method)]
  def matcher(false, method), do: never_matches(method)
  def matcher(spec = %{"$schema" => schema}, method), do: match_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method), do: match_id(spec, id, method)
  def matcher(spec = %{"type" => "string"}, method), do: match_string(spec, method)
  def matcher(spec = %{"type" => "integer"}, method), do: match_integer(spec, method)
  def matcher(spec = %{"type" => "number"}, method), do: match_number(spec, method)
  def matcher(spec = %{"type" => "object"}, method), do: match_object(spec, method)
  def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)

  @spec always_matches(atom) :: defblock
  defp always_matches(method) do
    quote do
      def unquote(method)(_val) do
        :ok
      end
    end
  end

  @spec never_matches(atom) :: [defblock]
  defp never_matches(method) do
    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
      end
    end]
  end

  @spec match_schema(map, String.t, atom) :: [defblock]
  def match_schema(map, schema, module) do
    rest = map
    |> Map.delete("$schema")
    |> matcher(module)


    [quote do
       def schema, do: unquote(schema)
     end | rest]
  end

  @spec match_id(map, String.t, atom) :: [defblock]
  def match_id(map, id, module) do
    rest = map
    |> Map.delete("$id")
    |> matcher(module)


    [quote do
      def id, do: unquote(id)
     end | rest]
  end

  @spec match_string(map, atom, boolean) :: [defblock]
  defp match_string(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_string_cond(method)
    |> BuildCond.build

    # TODO: make length value only appear if we have a length check.

    str_match = quote do
      def unquote(method)(val) when is_binary(val) do
        length = String.length(val)
        unquote(cond_stmt)
      end
    end

    if terminal do
      [str_match | never_matches(method)]
    else
      [str_match]
    end
  end

  @spec match_integer(map, atom, boolean) :: [defblock]
  defp match_integer(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_integer_cond(method)
    |> BuildCond.build

    num_match = quote do
      def unquote(method)(val) when is_integer(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [num_match | never_matches(method)]
    else
      [num_match]
    end
  end

  @spec match_number(map, atom, boolean) :: [defblock]
  defp match_number(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_number_cond(method)
    |> BuildCond.build

    num_match = quote do
      def unquote(method)(val) when is_number(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [num_match | never_matches(method)]
    else
      [num_match]
    end
  end

  @spec match_object(map, atom, boolean) :: [defblock]
  defp match_object(spec, method, terminal \\ true) do

    # build the conditional statement that guards on the object
    cond_stmt = spec
    |> build_object_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the object type
    dependencies = build_object_deps(spec, method)

    num_match = quote do
      def unquote(method)(val) when is_map(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [num_match | never_matches(method)] ++ dependencies
    else
      [num_match] ++ dependencies
    end
  end

  @spec match_list(map, list, atom) :: [defblock]
  defp match_list(_spec, [], method), do: never_matches(method)
  defp match_list(spec, ["string" | tail], method) do
    head_code = match_string(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["number" | tail], method) do
    head_code = match_number(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["object" | tail], method) do
    head_code = match_object(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["integer" | tail], method) do
    head_code = match_integer(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(any), do: any

  @spec mismatch(module, atom, any) :: {:mismatch, {module, atom, [any]}}
  def mismatch(m, f, a) do
    {:mismatch, {m, f, [a]}}
  end

  @spec build_string_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering strings based on their jsonschema
    parameters
  """
  def build_string_cond(spec = %{"maxLength" => length}, method) do
    [
      {
        quote do length > unquote(length) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maxLength")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(spec = %{"minLength" => length}, method) do
    [
      {
        quote do length < unquote(length) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minLength")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(spec = %{"pattern" => patt}, method) do
    [
      {
        quote do !(Regex.match?(sigil_r(<<unquote(patt)>>, ''), val)) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("pattern")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(_, _), do: []

  @spec build_integer_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering integers based on their jsonschema
    parameters
  """
  def build_integer_cond(spec = %{"multipleOf" => base}, method) do
    [
      {
        quote do rem(val, unquote(base)) != 0 end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("multipleOf")
      |> build_integer_cond(method)
    ]
  end
  def build_integer_cond(spec, module), do: build_number_cond(spec, module)

  @spec build_number_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering numbers based on their jsonschema
    parameters
  """
  def build_number_cond(spec = %{"minimum" => cmp}, method) do
    [
      {
        quote do val < unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minimum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"exclusiveMinimum" => cmp}, method) do
    [
      {
        quote do val <= unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMinimum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"maximum" => cmp}, method) do
    [
      {
        quote do val > unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maximum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"exclusiveMaximum" => cmp}, method) do
    [
      {
        quote do val >= unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMaximum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(_, _), do: []

  @spec build_object_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering objects based on their jsonschema
    parameters
  """
  def build_object_cond(spec = %{"dependencies" => dobj}, method) do
    Enum.map(dobj, fn {k, _v} ->
      dep_method = generate_submethod(method, k <> "_dependency")
      {
        quote do
          parse_prop_dep = Exonerate.Macro.check_property_dependency(
            val,
            unquote(k),
            __MODULE__,
            unquote(dep_method)
          )
        end,
        quote do
          parse_prop_dep
        end
      }
    end) ++
    (spec
    |> Map.delete("dependencies")
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"minProperties" => min}, method) do
    [{
      quote do
        Enum.count(val) < unquote(min)
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("minProperties")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"maxProperties" => max}, method) do
    [{
      quote do
        Enum.count(val) > unquote(max)
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("maxProperties")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"required" => plist}, method) do
    [{
      quote do
        ! Enum.all?(unquote(plist), &Map.has_key?(val, &1))
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("required")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"propertyNames" => _}, method) do
    pn_method = generate_submethod(method, "propertyNames")
    [{
      quote do
        parse_properties = Exonerate.Macro.check_property_names(
          val,
          __MODULE__,
          unquote(pn_method)
        )
      end,
      quote do parse_properties end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"additionalProperties" => _}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end
    ap_method = generate_submethod(method, "additionalProperties")
    [{
      quote do
        parse_additional = Exonerate.Macro.check_additional_properties(
                    val,
                    unquote(props),
                    __MODULE__,
                    unquote(ap_method))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalProperties")
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"properties" => pobj}, method) do
    Enum.map(pobj, fn {k, _v} ->
      new_method = generate_submethod(method, k)
      {
        quote do
          parse_recurse = Exonerate.Macro.check_property(
            val[unquote(k)],
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
    end) ++
    (spec
    |> Map.delete("properties")
    |> build_object_cond(method))
  end
  def build_object_cond(_, _), do: []

  @spec build_object_deps(Exonerate.schema, atom) :: [defblock]
  def build_object_deps(spec = %{"properties" => pobj}, method) do
    Enum.flat_map(pobj, &object_dep(&1, method)) ++
    build_object_deps(Map.delete(spec, "properties"), method)
  end
  def build_object_deps(spec = %{"propertyNames" => pobj}, method) do
    obj_string = Map.put(pobj, "type", "string")
    object_dep({"propertyNames", obj_string}, method) ++
    build_object_deps(Map.delete(spec, "propertyNames"), method)
  end
  def build_object_deps(spec = %{"additionalProperties" => pobj}, method) do
    object_dep({"additionalProperties", pobj}, method) ++
    build_object_deps(Map.delete(spec, "additionalProperties"), method)
  end
  def build_object_deps(spec = %{"dependencies" => dobj}, method) do
    object_property_dep(dobj, method) ++
    build_object_deps(Map.delete(spec, "dependencies"), method)
  end
  def build_object_deps(_, _), do: []

  def object_property_dep(dobj, method) do
    Enum.flat_map(dobj, &property_dep(&1, method))
  end

  def check_property_dependency(map, key, module, method) do
    Map.has_key?(map, key) &&
    (
      module
      |> apply(method, [map])
      |> case do
        :ok -> false
        any -> any
      end
    )
  end

  def property_dep({k, v}, method) when is_list(v) do
    dep_method = generate_submethod(method, k <> "_dependency")
    [quote do
      def unquote(dep_method)(val) do
        prop_list = unquote(v)
        if Enum.all?(prop_list, &Map.has_key?(val, &1)) do
          :ok
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(dep_method), val)
        end
      end
    end]
  end
  def property_dep({k, v}, method) when is_map(v) do
    dep_method = generate_submethod(method, k <> "_dependency")
    v
    |> Map.put("type", "object")
    |> matcher(dep_method)
  end

  #TODO: rename this thing.
  @spec object_dep({String.t, Exonerate.schema}, atom) :: [defblock]
  def object_dep({k, v}, method) do
    new_method = generate_submethod(method, k)
    matcher(v, new_method)
  end

  @spec generate_submethod(atom, String.t) :: atom
  defp generate_submethod(method, sub) do
    method
    |> Atom.to_string
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end

  def check_property_names(obj, module, pn_method) do
    try do
      Enum.each(obj, &check_property_name(&1, module, pn_method))
      false
    catch
      any -> any
    end
  end

  def check_property_name({k, _v}, module, pn_method) do
    module
    |> apply(pn_method, [k])
    |> throw_if_invalid
  end

  def check_additional_properties(obj, list, module, ap_method) do
    try do
      Enum.each(obj, &check_additional_property(&1, list, module, ap_method))
      false
    catch
      any -> any
    end
  end

  def check_additional_property({k, v}, list, module, ap_method) do
    if k in list do
      :ok
    else
      module
      |> apply(ap_method, [v])
      |> throw_if_invalid
    end
  end

  def check_property(nil, _, _), do: nil
  def check_property(obj, module, property_method) do
    module
    |> apply(property_method, [obj])
    |> case do
      :ok -> false
      any -> any
    end
  end

  def throw_if_invalid(:ok), do: :ok
  def throw_if_invalid(any), do: throw any

end
