defmodule Exonerate.Check do

  @type json :: Exonerate.json
  @type mismatch :: Exonerate.mismatch
  @type check_fn :: ((json) -> :ok | mismatch)

  @spec throw_check(json, check_fn) :: :ok | no_return
  defp throw_check(value, function) do
    value
    |> function.()
    |> throw_if_invalid
  end

  @spec object_pattern_properties(json, Regex.t, check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "patternProperties" parameter for a
  JSONschema are obeyed.  Is passed the atom representing the pregenerated
  property name checker, associated with a particular regex.
  """
  def object_pattern_properties(obj, regex, check_fn) do
    try do
      obj
      |> Map.keys
      |> Enum.filter(&Regex.match?(regex, &1))
      |> Enum.each(&throw_check(obj[&1], check_fn))
      false
    catch
      any -> any
    end
  end


  @spec object_property_names(json, check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "propertyNames" parameter for a
  JSONschema are obeyed.  Is passed the atom representing the pregenerated
  property name checker.  This presumably checks against a constant array
  of strings representing acceptable keys.
  """
  def object_property_names(obj, check_fn) do
    # note we're going to explicitly use the throw/catch methodology here to
    # short-circuit the "each" function.
    try do
      Enum.each(obj, fn {k, _v} -> throw_check(k, check_fn) end)
      false
    catch
      any -> any
    end
  end

  @spec object_property(json, check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "properties" parameter for a JSONschema
  are obeyed, being passed the atom representing the pregenerated property
  method that should exist.
  """
  def object_property(nil, _), do: false
  def object_property(obj, check_fn) do
    obj
    |> check_fn.()
    |> case do
      :ok -> false
      any -> any
    end
  end

  @spec object_additional_properties(json, [String.t], check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalProperties" parameter for a
  JSONSchema are obeyed.  Also passed is a list of keys that are already
  accounted for in the "properties" part of the JSONSchema
  """
  def object_additional_properties(obj, list, check_fn) do
    # note we're going to explicitly use the throw/catch methodology here to
    # short-circuit the "each" function.
    try do
      Enum.each(obj, &object_additional_property(&1, list, check_fn))
      false
    catch
      any -> any
    end
  end

  @spec object_additional_property({String.t, json}, [String.t], check_fn) :: :ok | no_return
  defp object_additional_property({k, v}, list, check_fn) do
    # singularized version of object_additional_properties, this is the function
    # that is mapped over. Needs to throw a mismatch tuple if there is a mismatch.
    if k in list do
      :ok
    else
      throw_check(v, check_fn)
    end
  end

  @spec object_additional_properties(json, [String.t], [Regex.t], check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalProperties" parameter for a
  JSONSchema are obeyed.  Also passed is a list of keys that are already
  accounted for in the "properties" part of the JSONSchema, and the list
  of regexes that need to be accounted for to trigger
  """
  def object_additional_properties(obj, list, regexes, check_fn) do
    try do
      Enum.each(obj, &object_additional_property(&1, list, regexes, check_fn))
      false
    catch
      any -> any
    end
  end

  @spec object_additional_property({String.t, json}, [String.t], [Regex.t], check_fn) :: :ok | no_return
  def object_additional_property({k, v}, list, regexes, check_fn) do
    # singularized version of object_additional_properties, this is the function
    # that is mapped over.  Needs to throw a mismatch tuple if there is a mismatch.
    cond do
      k in list -> :ok
      regexes
      |> Enum.map(&Regex.match?(&1, k))
      |> Enum.any? -> :ok
      true ->
        throw_check(v, check_fn)
    end
  end

  @spec object_property_dependency(json, String.t, check_fn) :: false | mismatch
  def object_property_dependency(map, key, check_fn) do
    Map.has_key?(map, key) &&
    (
      map
      |> check_fn.()
      |> case do
        :ok -> false
        any -> any
      end
    )
  end

  @spec array_additional_items([json], non_neg_integer, check_fn) :: false | mismatch
  @doc """
  a trampoline that checks that the "additionalItems" parameter for a
  JSONSchema are obeyed.  Also passed is the length of the original array
  """
  def array_additional_items(arr, ignore_count, check_fn) do
    try do
      arr
      |> Enum.with_index
      |> Enum.each(fn
        {_, idx} when idx < ignore_count -> :ok
        {val, _} -> throw_check(val, check_fn)
      end)
      false
    catch
      any -> any
    end
  end

  @spec array_items(json, check_fn) :: false | mismatch
  def array_items(val, check_fn) do
    try do
      Enum.each(val, &throw_check(&1, check_fn))
      false
    catch
      any -> any
    end
  end

  @spec array_tuple(json, non_neg_integer, check_fn) :: false | mismatch
  def array_tuple(val, idx, check_fn) do
    check_val = Enum.at(val, idx)
    check_val && (
      check_val
      |> check_fn.()
      |> continue_if_ok
    )
  end

  @spec array_contains_not(json, check_fn) :: false | true
  def array_contains_not(val, check_fn) do
    if Enum.any?(val, &(check_fn.(&1) == :ok)) do
      false
    else
      true
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
