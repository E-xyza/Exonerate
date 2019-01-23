defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Macro.BuildCond
  alias Exonerate.Macro.Combining
  alias Exonerate.Macro.MatchEnum
  alias Exonerate.Macro.MatchNumber
  alias Exonerate.Macro.MatchObject
  alias Exonerate.Macro.MatchString
  alias Exonerate.Macro.Metadata

  @type json     :: Exonerate.json
  @type specmap  :: %{optional(String.t) => json}
  @type condlist :: [BuildCond.condclause]
  @type defblock :: {:def, any, any}

  defmacro defschema([{method, json} | _opts]) do

    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    quote do
      unquote_splicing(code)
    end
  end

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec matcher(json, atom)::[defblock | {:__block__, any, any}]
  def matcher(true, method), do: always_matches(method)
  def matcher(false, method), do: never_matches(method)
  # metadata things
  def matcher(spec = %{"title" => title}, method),       do: Metadata.set_title(spec, title, method)
  def matcher(spec = %{"description" => desc}, method),  do: Metadata.set_description(spec, desc, method)
  def matcher(spec = %{"default" => default}, method),   do: Metadata.set_default(spec, default, method)
  def matcher(spec = %{"examples" => examples}, method), do: Metadata.set_examples(spec, examples, method)
  def matcher(spec = %{"$schema" => schema}, method),    do: Metadata.set_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method),            do: Metadata.set_id(spec, id, method)
  # match enums and consts
  def matcher(spec = %{"enum" => elist}, method),        do: MatchEnum.match_enum(spec, elist, method)
  def matcher(spec = %{"const" => const}, method),       do: MatchEnum.match_const(spec, const, method)
  # match combining elements
  def matcher(spec = %{"allOf" => clist}, method),       do: Combining.match_allof(spec, clist, method)
  def matcher(spec = %{"anyOf" => clist}, method),       do: Combining.match_anyof(spec, clist, method)
  def matcher(spec = %{"oneOf" => clist}, method),       do: Combining.match_oneof(spec, clist, method)
  def matcher(spec = %{"not" => inv}, method),           do: Combining.match_not(spec, inv, method)
  # type matching things
  def matcher(spec, method) when spec == %{},            do: always_matches(method)
  def matcher(spec = %{"type" => "boolean"}, method),    do: match_boolean(spec, method)
  def matcher(spec = %{"type" => "null"}, method),       do: match_null(spec, method)
  def matcher(spec = %{"type" => "string"}, method),     do: MatchString.match(spec, method)
  def matcher(spec = %{"type" => "integer"}, method),    do: MatchNumber.match_int(spec, method)
  def matcher(spec = %{"type" => "number"}, method),     do: MatchNumber.match(spec, method)
  def matcher(spec = %{"type" => "object"}, method),     do: MatchObject.match(spec, method)
  def matcher(spec = %{"type" => "array"}, method), do: match_array(spec, method)
  def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)
  def matcher(spec, method), do: match_list(spec, @all_types, method)

  @spec always_matches(atom) :: [defblock]
  def always_matches(method) do
    [quote do
      def unquote(method)(_val) do
        :ok
      end
    end]
  end

  @spec never_matches(atom) :: [defblock]
  def never_matches(method) do
    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
      end
    end]
  end

  @spec match_boolean(map, atom, boolean) :: [defblock]
  defp match_boolean(_spec, method, terminal \\ true) do

    bool_match = quote do
      def unquote(method)(val) when is_boolean(val) do
        :ok
      end
    end

    if terminal do
      [bool_match | never_matches(method)]
    else
      [bool_match]
    end
  end

  @spec match_null(map, atom, boolean) :: [defblock]
  defp match_null(_spec, method, terminal \\ true) do

    null_match = quote do
      def unquote(method)(val) when is_nil(val) do
        :ok
      end
    end

    if terminal do
      [null_match | never_matches(method)]
    else
      [null_match]
    end
  end

  @spec match_array(map, atom, boolean) :: [defblock]
  defp match_array(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_array_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the array type
    dependencies = build_array_deps(spec, method)

    arr_match = quote do
      def unquote(method)(val) when is_list(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [arr_match | never_matches(method)] ++ dependencies
    else
      [arr_match] ++ dependencies
    end
  end

  @spec match_list(map, list, atom) :: [defblock]
  defp match_list(_spec, [], method), do: never_matches(method)
  defp match_list(spec, ["string" | tail], method) do
    head_code = MatchString.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["integer" | tail], method) do
    head_code = MatchNumber.match_int(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["number" | tail], method) do
    head_code = MatchNumber.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["object" | tail], method) do
    head_code = MatchObject.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["array" | tail], method) do
    head_code = match_array(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["boolean" | tail], method) do
    head_code = match_boolean(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["null" | tail], method) do
    head_code = match_null(spec, method, false)
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

  def build_array_cond(spec = %{"additionalItems" => _props, "items" => parr}, method) when is_list(parr) do
    #this only gets triggered when we have a tuple list.
    ap_method = generate_submethod(method, "additional_items")
    length = Enum.count(parr)
    [{
      quote do
        parse_additional = Exonerate.Macro.check_additional_array(
                    val,
                    unquote(length),
                    __MODULE__,
                    unquote(ap_method))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalItems")
    |> build_array_cond(method))
  end
  def build_array_cond(spec = %{"items" => parr}, method) when is_list(parr) do
    for idx <- 0..(Enum.count(parr) - 1) do
      new_method = generate_submethod(method, "item_#{idx}")
      {
        quote do
          parse_recurse = Exonerate.Macro.check_tuple(
            val,
            unquote(idx),
            __MODULE__,
            unquote(new_method)
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
      |> build_array_cond(method))
  end
  def build_array_cond(spec = %{"items" => _pobj}, method) do
    new_method = generate_submethod(method, "items")
    [
      {
        quote do
          parse_recurse = Exonerate.Macro.check_items(
            val,
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("items")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"contains" => _pobj}, method) do
    new_method = generate_submethod(method, "contains")
    [
      {
        quote do
          parse_recurse = Exonerate.Macro.check_contains(
            val,
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("contains")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"minItems" => items}, method) do
    [
      {
        quote do Enum.count(val) < unquote(items) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("minItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"maxItems" => items}, method) do
    [
      {
        quote do Enum.count(val) > unquote(items) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("maxItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"uniqueItems" => true}, method) do
    [
      {
        quote do Exonerate.Macro.contains_duplicate?(val) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("uniqueItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(_spec, _method), do: []

  def build_array_deps(spec = %{"additionalItems" => props, "items" => parr}, method) when is_list(parr) do
    array_additional_dep(props, method) ++
    build_array_deps(Map.delete(spec, "additionalItems"), method)
  end
  def build_array_deps(spec = %{"items" => iobj}, method) do
    array_items_dep(iobj, method) ++
    build_array_deps(Map.delete(spec, "items"), method)
  end
  def build_array_deps(spec = %{"contains" => cobj}, method) do
    array_contains_dep(cobj, method) ++
    build_array_deps(Map.delete(spec, "contains"), method)
  end
  def build_array_deps(_,_), do: []

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

  def array_additional_dep(prop, method) do
    add_method = generate_submethod(method, "additional_items")
    matcher(prop, add_method)
  end

  def array_items_dep(iarr, method) when is_list(iarr) do
    iarr
    |> Enum.with_index
    |> Enum.flat_map(fn {spec, idx} ->
      item_method = generate_submethod(method, "item_#{idx}")
      matcher(spec, item_method)
    end)
  end
  def array_items_dep(iobj, method) do
    items_method = generate_submethod(method, "items")
    matcher(iobj, items_method)
  end

  def array_contains_dep(cobj, method) do
    contains_method = generate_submethod(method, "contains")
    matcher(cobj, contains_method)
  end

  @spec generate_submethod(atom, String.t) :: atom
  defp generate_submethod(method, sub) do
    method
    |> Atom.to_string
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end

  def reduce_any(module, functions, base, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.any?(&(&1 == :ok))
    |> if do
      apply(module, base, args)
    else
      {:mismatch, {module, method, args}}
    end
  end

  def reduce_all(module, functions, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.all?(&(&1 == :ok))
    |> if do
      :ok
    else
      {:mismatch, {module, method, args}}
    end
  end

  def reduce_one(module, functions, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.count(&(&1 == :ok))
    |> case do
      1 -> :ok
      _ -> {:mismatch, {module, method, args}}
    end
  end

  def apply_not(module, method, args) do
    module
    |> apply(method, args)
    |> case do
      :ok -> {:mismatch, {module, method, args}}
      {:mismatch, _} -> :ok
    end
  end

  def check_pattern_properties(obj, regex, module, pp_method) do
    try do
      obj
      |> Map.keys
      |> Enum.filter(&Regex.match?(regex, &1))
      |> Enum.each(&check_pattern_property(obj[&1], module, pp_method))
      false
    catch
      any -> any
    end
  end

  def check_pattern_property(value, module, pp_method) do
    module
    |> apply(pp_method, [value])
    |> throw_if_invalid
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
  def check_additional_properties(obj, list, regexes, module, ap_method) do
    try do
      Enum.each(obj, &check_additional_property(&1, list, regexes, module, ap_method))
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

  def check_additional_property({k, v}, list, regexes, module, ap_method) do
    cond do
      k in list -> :ok
      regexes
      |> Enum.map(&Regex.match?(&1, k))
      |> Enum.any? -> :ok
      true ->
        module
        |> apply(ap_method, [v])
        |> throw_if_invalid
    end
  end

  def check_additional_array(arr, tuple_count, module, ap_method) do
    try do
      arr
      |> Enum.with_index
      |> Enum.each(fn
        {_, idx} when idx < tuple_count -> :ok
        {val, _} ->
          module
          |> apply(ap_method, [val])
          |> throw_if_invalid
      end)
      false
    catch
      any -> any
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

  def check_items(val, module, item_method) do
    try do
      Enum.each(val, &check_item(&1, module, item_method))
      false
    catch
      any -> any
    end
  end
  def check_item(val, module, item_method) do
    module
    |> apply(item_method, [val])
    |> throw_if_invalid
  end

  def check_tuple(val, idx, module, item_method) do
    check_val = Enum.at(val, idx)
    check_val && (
      module
      |> apply(item_method, [check_val])
      |> continue_if_ok
    )
  end

  def check_contains(val, module, cont_method) do
    if Enum.any?(val, &(apply(module, cont_method, [&1]) == :ok)) do
      :ok
    else
      Exonerate.Macro.mismatch(module, cont_method, val)
    end
  end

  def contains_duplicate?(array), do: contains_duplicate?(array, MapSet.new())
  def contains_duplicate?([], _), do: false
  def contains_duplicate?([head | tail], set) do
    if MapSet.member?(set, head) do
      true
    else
      contains_duplicate?(tail, MapSet.put(set, head))
    end
  end

  def throw_if_invalid(:ok), do: :ok
  def throw_if_invalid(any), do: throw any

  def continue_if_ok(:ok), do: false
  def continue_if_ok(any), do: any

end
