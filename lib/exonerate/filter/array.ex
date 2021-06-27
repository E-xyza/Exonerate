defmodule Exonerate.Filter.Array do
  @moduledoc false
  # the filter for "array" parameters

  alias Exonerate.Filter
  import Filter, only: [drop_type: 2]

  @behaviour Filter

  defguardp has_array_props(schema) when
    is_map_key(schema, "contains") or
    is_map_key(schema, "items") or
    is_map_key(schema, "minItems") or
    is_map_key(schema, "maxItems") or
    is_map_key(schema, "uniqueItems") or
    is_map_key(schema, "additionalItems") or
    is_map_key(schema, "prefixItems")

  @impl true
  def filter(schema, state = %{types: types}) when has_array_props(schema) and is_map_key(types, :array) do
    {[array_filter(schema, state.path)], drop_type(state, :array)}
  end
  def filter(_schema, state) do
    {[], state}
  end

  def array_filter(schema, schema_path) do
    quote do
      defp unquote(schema_path)(list, path) when is_list(list) do
        unquote(prefix_validation(schema, schema_path))
        initial! = %{index: 0}
        unquote(unique_initializer(schema))
        unquote(contains_initializer(schema, schema_path))
        unquote(tuple_initializer(schema, schema_path))
        reduction = Enum.reduce(list, initial!, fn item, acc! ->
          unquote(max_items_validation(schema))
          unquote(unique_validation(schema))
          unquote(items_validation(schema, schema_path))
          unquote(tuple_validation(schema, schema_path))
          unquote(contains_iterator(schema))
          %{acc! | index: acc!.index + 1}
        end)
        unquote(min_items_validation(schema))
        unquote(contains_validation(schema))
        :ok
      end
      unquote(items_helper(schema, schema_path))
      unquote(contains_helper(schema, schema_path))
      unquote_splicing(tuple_helpers(schema, schema_path))
      unquote_splicing(prefix_helpers(schema, schema_path))
      unquote(additional_items_helpers(schema, schema_path))
    end
  end

  defp unique_initializer(%{"uniqueItems" => true}) do
    quote do
      initial! = Map.put(initial!, :uniques, MapSet.new())
    end
  end
  defp unique_initializer(_), do: :ok

  defp unique_validation(%{"uniqueItems" => true}) do
    quote do
      if item in acc!.uniques, do:
        Exonerate.mismatch(
          item,
          Path.join(path, "#{acc!.index}"),
          schema_subpath: "uniqueItems")

      acc! = %{acc! | uniques: MapSet.put(acc!.uniques, item)}
    end
  end
  defp unique_validation(_), do: :ok

  defguardp needs_contain_count(schema) when
    is_map_key(schema, "minContains") or
    is_map_key(schema, "maxContains")

  defp contains_initializer(schema = %{"contains" => _}, schema_path)
      when needs_contain_count(schema) do
    contains_path = Exonerate.join(schema_path, "contains")
    lambda = {:&, [], [{:/, [], [{contains_path, [], Elixir}, 2]}]}
    quote do
      initial! = Map.put(initial!, :contains, {unquote(lambda), 0})
    end
  end
  defp contains_initializer(%{"contains" => _}, schema_path) do
    contains_path = Exonerate.join(schema_path, "contains")
    lambda = {:&, [], [{:/, [], [{contains_path, [], Elixir}, 2]}]}
    quote do
      initial! = Map.put(initial!, :contains, unquote(lambda))
    end
  end
  defp contains_initializer(_, _), do: :ok

  defp contains_iterator(schema = %{"contains" => _}) when needs_contain_count(schema) do
    validate_max_contains = if max = schema["maxContains"] do
      quote do
        if elem(acc!.contains, 1) > unquote(max) do
          Exonerate.mismatch(list, path, schema_subpath: "maxContains")
        end
      end
    end

    quote do
      {contains, count} = acc!.contains
      acc! = try do
        contains.(item, path)
        %{acc! | contains: {contains, count + 1}}
      catch
        {:mismatch, _} -> acc!
      end
      unquote(validate_max_contains)
    end
  end
  defp contains_iterator(%{"contains" => _}) do
    quote do
      acc! = try do
        if contains = acc![:contains] do
          contains.(item, path)
          Map.delete(acc!, :contains)
        else
          acc!
        end
      catch
        {:mismatch, _} -> acc!
      end
    end
  end
  defp contains_iterator(_), do: :ok

  defp contains_validation(schema = %{"contains" => _}) when needs_contain_count(schema) do
    if min = schema["minContains"] do
      quote do
        {contains, count} = reduction.contains
        if count < unquote(min) do
          Exonerate.mismatch(list, path, schema_subpath: "minContains")
        end
      end
    else
      quote do
        {contains, count} = reduction.contains
        if count == 0 do
          Exonerate.mismatch(list, path, schema_subpath: "contains")
        end
      end
    end
  end
  defp contains_validation(%{"contains" => _}) do
    quote do
      if is_map_key(reduction, :contains) do
        Exonerate.mismatch(list, path, schema_subpath: "contains")
      end
    end
  end
  defp contains_validation(_), do: :ok

  defp contains_helper(%{"contains" => inner_schema}, schema_path) do
    contains_path = Exonerate.join(schema_path, "contains")
    Filter.from_schema(inner_schema, contains_path)
  end
  defp contains_helper(_, _), do: :ok

  defp tuple_initializer(%{"items" => tuple}, schema_path) when is_list(tuple) do
    funs = tuple
    |> Enum.with_index
    |> Enum.map(fn {_, index} ->
      tuple_path = Exonerate.join(schema_path, "items/#{index}")
      {index, {:&, [], [{:/, [], [{tuple_path, [], Elixir}, 2]}]}}
    end)

    tuple_map = {:%{}, [], funs}
    quote do
      initial! = Map.merge(initial!, unquote(tuple_map))
    end
  end
  defp tuple_initializer(_, _), do: :ok

  defp tuple_validation(schema = %{"items" => tuple}, schema_path) when is_list(tuple) do
    quote do
      if fun = acc![acc!.index] do
        fun.(item, Path.join(path, "#{acc!.index}"))
      else
        unquote(additional_items_call(schema, schema_path))
      end
    end
  end
  defp tuple_validation(_, _), do: :ok

  defp tuple_helpers(%{"items" => tuple}, schema_path) when is_list(tuple) do
    tuple
    |> Enum.with_index
    |> Enum.map(fn {inner_schema, index} ->
      tuple_path = Exonerate.join(schema_path, "items/#{index}")
      Filter.from_schema(inner_schema, tuple_path)
    end)
  end
  defp tuple_helpers(_, _), do: []

  defp max_items_validation(%{"maxItems" => max_items}) do
    quote do
      if acc!.index == unquote(max_items), do:
      Exonerate.mismatch(list, path, schema_subpath: "maxItems")
    end
  end
  defp max_items_validation(_), do: :ok

  defp min_items_validation(%{"minItems" => min_items}) do
    quote do
      if reduction.index < unquote(min_items), do:
       Exonerate.mismatch(list, path, schema_subpath: "minItems")
    end
  end
  defp min_items_validation(_), do: :ok

  defp prefix_validation(%{"prefixItems" => _items}, schema_path) do
    prefix_path = Exonerate.join(schema_path, "prefixItems")
    quote do
      unquote(prefix_path)(list, path)
    end
  end
  defp prefix_validation(_, _), do: :ok

  defp prefix_helpers(%{"prefixItems" => schemas}, schema_path) do
    prefix_path = Exonerate.join(schema_path, "prefixItems")

    {call_list, filters} = schemas
    |> Enum.with_index
    |> Enum.map(fn {schema, index} ->
      call_path = Exonerate.join(prefix_path, to_string(index))
      filter = Filter.from_schema(schema, call_path)
      {{:&, [], [{:/, [], [{call_path, [], Elixir}, 2]}]}, filter}
    end)
    |> Enum.unzip

    [quote do
      defp unquote(prefix_path)(list, path) do
        list
        |> Enum.with_index()
        |> Enum.zip(unquote(call_list))
        |> Enum.each(fn {{item, index}, validator} ->
          validator.(item, Path.join(path, to_string(index)))
        end)
      end
    end] ++ filters

    #{args, checks} = schemas
    #|> Enum.with_index
    #|> Enum.map(fn {schema, index} ->
    #  arg = {String.to_atom("arg#{index}"), [], Elixir}
    #  check_path = Exonerate.join(prefix_path, "#{index}")
    #  call = {check_path, [], [arg, quote do Path.join(unquote({:path, [], Elixir}), unquote(to_string index)) end]}
    #  validator = Filter.from_schema(schema, check_path)
    #  {arg, {call, validator}}
    #end)
    #|> Enum.unzip
#
    #[first | rest] = Enum.reverse(args)
    #args_with_rest = Enum.reverse(rest, [{:|, [], [first, {:_, [], Elixir}]}])
#
    #{body, validators} = Enum.unzip(checks)
#
    #args = [args_with_rest, {:path, [], Elixir}]
    #fallback = quote do
    #  defp unquote(prefix_path)(list, path) do
    #    Exonerate.mismatch(list, path)
    #  end
    #end
    #[{:defp, [], [{prefix_path, [], args}, [do: {:__block__, [], body}]]}, fallback] ++ validators
  end
  defp prefix_helpers(_, _), do: []

  defp items_validation(%{"items" => items}, schema_path) when is_map(items) or is_boolean(items) do
    items_path = Exonerate.join(schema_path, "items")
    quote do
      unquote(items_path)(item, Path.join(path, "#{acc!.index}"))
    end
  end
  defp items_validation(_, _), do: :ok

  defp items_helper(%{"items" => items}, schema_path) when is_map(items) or is_boolean(items) do
    items_path = Exonerate.join(schema_path, "items")
    Filter.from_schema(items, items_path)
  end
  defp items_helper(_, _), do: :ok

  defp additional_items_call(%{"additionalItems" => _}, schema_path) do
    additional_items_path = Exonerate.join(schema_path, "additionalItems")
    quote do
      unquote(additional_items_path)(item, Path.join(path, "#{acc!.index}"))
    end
  end
  defp additional_items_call(_, _), do: :ok

  defp additional_items_helpers(%{"additionalItems" => schema}, schema_path) do
    additional_items_path = Exonerate.join(schema_path, "additionalItems")
    Filter.from_schema(schema, additional_items_path)
  end
  defp additional_items_helpers(_, _), do: :ok
end
