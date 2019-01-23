defmodule Exonerate.Check do

  @type json :: Exonerate.json
  @type mismatch :: Exonerate.mismatch

  @spec throw_check(json, module, atom) :: :ok | no_return
  defp throw_check(value, module, method) do
    # a simple throwing checker.  Used for methods which employ Enum
    # shortcutting.
    module
    |> apply(method, [value])
    |> throw_if_invalid
  end

  @spec object_pattern_properties(json, Regex.t, module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "patternProperties" parameter for a
  JSONschema are obeyed.  Is passed the atom representing the pregenerated
  property name checker, associated with a particular regex.
  """
  def object_pattern_properties(obj, regex, module, pp_method) do
    try do
      obj
      |> Map.keys
      |> Enum.filter(&Regex.match?(regex, &1))
      |> Enum.each(&throw_check(obj[&1], module, pp_method))
      false
    catch
      any -> any
    end
  end


  @spec object_property_names(json, module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "propertyNames" parameter for a
  JSONschema are obeyed.  Is passed the atom representing the pregenerated
  property name checker.  This presumably checks against a constant array
  of strings representing acceptable keys.
  """
  def object_property_names(obj, module, pn_method) do
    # note we're going to explicitly use the throw/catch methodology here to
    # short-circuit the "each" function.
    try do
      Enum.each(obj, fn {k, _v} -> throw_check(k, module, pn_method) end)
      false
    catch
      any -> any
    end
  end

  @spec object_property(json, module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "properties" parameter for a JSONschema
  are obeyed, being passed the atom representing the pregenerated property
  method that should exist.
  """
  def object_property(nil, _, _), do: false
  def object_property(obj, module, property_method) do
    module
    |> apply(property_method, [obj])
    |> case do
      :ok -> false
      any -> any
    end
  end

  @spec object_additional_properties(json, [String.t], module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalProperties" parameter for a
  JSONSchema are obeyed.  Also passed is a list of keys that are already
  accounted for in the "properties" part of the JSONSchema
  """
  def object_additional_properties(obj, list, module, ap_method) do
    # note we're going to explicitly use the throw/catch methodology here to
    # short-circuit the "each" function.
    try do
      Enum.each(obj, &object_additional_property(&1, list, module, ap_method))
      false
    catch
      any -> any
    end
  end

  @spec object_additional_property({String.t, json}, [String.t], module, atom) :: :ok | no_return
  defp object_additional_property({k, v}, list, module, ap_method) do
    # singularized version of object_additional_properties, this is the function
    # that is mapped over. Needs to throw a mismatch tuple if there is a mismatch.
    if k in list do
      :ok
    else
      throw_check(v, module, ap_method)
    end
  end

  @spec object_additional_properties(json, [String.t], [Regex.t], module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalProperties" parameter for a
  JSONSchema are obeyed.  Also passed is a list of keys that are already
  accounted for in the "properties" part of the JSONSchema, and the list
  of regexes that need to be accounted for to trigger
  """
  def object_additional_properties(obj, list, regexes, module, ap_method) do
    try do
      Enum.each(obj, &object_additional_property(&1, list, regexes, module, ap_method))
      false
    catch
      any -> any
    end
  end

  @spec object_additional_property({String.t, json}, [String.t], [Regex.t], module, atom) :: :ok | no_return
  def object_additional_property({k, v}, list, regexes, module, ap_method) do
    # singularized version of object_additional_properties, this is the function
    # that is mapped over.  Needs to throw a mismatch tuple if there is a mismatch.
    cond do
      k in list -> :ok
      regexes
      |> Enum.map(&Regex.match?(&1, k))
      |> Enum.any? -> :ok
      true ->
        throw_check(v, module, ap_method)
    end
  end

  @spec array_additional_items([json], non_neg_integer, module, atom) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalItems" parameter for a
  JSONSchema are obeyed.  Also passed is the length of the original array
  """
  def array_additional_items(arr, ignore_count, module, ai_method) do
    try do
      arr
      |> Enum.with_index
      |> Enum.each(fn
        {_, idx} when idx < ignore_count -> :ok
        {val, _} -> throw_check(val, module, ai_method)
      end)
      false
    catch
      any -> any
    end
  end

  @spec array_items(json, module, atom) :: false | mismatch
  def array_items(val, module, item_method) do
    try do
      Enum.each(val, &throw_check(&1, module, item_method))
      false
    catch
      any -> any
    end
  end

  @spec array_tuple(json, non_neg_integer, module, atom) :: false | mismatch
  def array_tuple(val, idx, module, item_method) do
    check_val = Enum.at(val, idx)
    check_val && (
      module
      |> apply(item_method, [check_val])
      |> continue_if_ok
    )
  end

  @spec array_contains(json, module, atom) :: false | mismatch
  def array_contains(val, module, cont_method) do
    if Enum.any?(val, &(apply(module, cont_method, [&1]) == :ok)) do
      :ok
    else
      Exonerate.Macro.mismatch(module, cont_method, val)
    end
  end

  @spec contains_duplicate?([json]) :: boolean
  def contains_duplicate?(array), do: contains_duplicate?(array, MapSet.new())

  @spec contains_duplicate?([json], MapSet.t) :: boolean
  defp contains_duplicate?([], _), do: false
  defp contains_duplicate?([head | tail], set) do
    if MapSet.member?(set, head) do
      true
    else
      contains_duplicate?(tail, MapSet.put(set, head))
    end
  end

  @spec throw_if_invalid(:ok | mismatch) :: :ok | no_return
  def throw_if_invalid(:ok), do: :ok
  def throw_if_invalid(any), do: throw any

  @spec continue_if_ok(:ok | mismatch) :: false | mismatch
  def continue_if_ok(:ok), do: false
  def continue_if_ok(any), do: any

end
