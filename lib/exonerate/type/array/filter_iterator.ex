defmodule Exonerate.Type.Array.FilterIterator do
  @moduledoc false

  # macros for "filter-mode" array filtering.  This is for cases when rejecting
  # the array occurs when a single item fails with error, this is distinct from
  # when the accepting the array occurs when a single item passes with :ok.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_iterator(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # at its core, the iterator is a reduce-while that encapsulates a with statement.
  # the reduce-while operates over the entire array.

  defp build_iterator(context, authority, pointer, opts) do
    call = Iterator.call(authority, pointer, opts)
    accumulator = accumulator(context)
    tracked = !!opts[:tracked]
    reduction = reduction(context, accumulator, authority, pointer, opts)

    if finalizer = finalizer_for(context, tracked, accumulator, pointer) do
      quote do
        defp unquote(call)(unquote_splicing(call_parameters(context))) do
          unquote(reduction)
          |> unquote(finalizer)
        end
      end
    else
      quote do
        defp unquote(call)(unquote_splicing(call_parameters(context))) do
          unquote(reduction)
        end
      end
    end
  end

  defp reduction(context, accumulator, authority, pointer, opts) do
    quote do
      Enum.reduce_while(array, {:ok, unquote(init(accumulator))}, fn
        item, {:ok, accumulator} ->
          unquote(with_statement(context, accumulator, authority, pointer, opts))
      end)
    end
  end

  # SNIPPETS

  @seen_filters ~w(allOf anyOf if oneOf $ref)

  # we need three parameters if and only if:
  # - context has unevaluatedItems
  # - context has seen combining filters
  defp call_parameters(context) do
    if passed_unseen_index?(context) do
      quote do
        [array, path, first_unseen_index]
      end
    else
      quote do
        [array, path]
      end
    end
  end

  defp passed_unseen_index?(context = %{"unevaluatedItems" => _}) do
    Enum.any?(@seen_filters, &is_map_key(context, &1))
  end

  defp passed_unseen_index?(_), do: false

  defp init([]), do: 0

  defp init(accumulator) when is_list(accumulator) do
    {:%{}, [], Enum.map([:index | accumulator], &init/1)}
  end

  defp init(:index), do: {:index, 0}

  defp init(:contains), do: {:contains, 0}

  defp init(:so_far) do
    {:so_far,
     quote do
       MapSet.new()
     end}
  end

  defp index([]) do
    quote do
      accumulator
    end
  end

  defp index([_ | _]) do
    quote do
      accumulator.index
    end
  end

  defp next([]) do
    quote do
      accumulator + 1
    end
  end

  defp next(list) when is_list(list) do
    quote do
      %{accumulator | unquote_splicing(Enum.map([:index | list], &next/1))}
    end
  end

  defp next(:index) do
    quote do
      {:index, accumulator.index + 1}
    end
  end

  defp next(:so_far) do
    quote do
      {:so_far, MapSet.put(accumulator.so_far, item)}
    end
  end

  defp next(:contains) do
    quote do
      {:contains, new_contains}
    end
  end

  # CODE BLOCKS

  defp with_statement(context, accumulator, authority, pointer, opts) do
    filters =
      context
      |> Enum.sort()
      |> Enum.flat_map(&List.wrap(filter_for(&1, context, accumulator, authority, pointer, opts)))

    quote do
      require Exonerate.Tools

      with unquote_splicing(filters) do
        {:cont, {:ok, unquote(next(accumulator))}}
      else
        Exonerate.Tools.error_match(error) -> {:halt, {error}}
      end
    end
  end

  defp filter_for({"maxItems", _}, _, accumulator, authority, pointer, opts) do
    max_items_call = Tools.call(authority, JsonPointer.join(pointer, "maxItems"), opts)

    quote do
      :ok <- unquote(max_items_call)(array, unquote(index(accumulator)), path)
    end
  end

  defp filter_for({"uniqueItems", true}, _, accumulator, authority, pointer, opts) do
    # just a basic assertion here for safety
    :so_far in accumulator or raise "uniqueItems without :so_far in accumulator"

    unique_items_call = Tools.call(authority, JsonPointer.join(pointer, "uniqueItems"), opts)

    quote do
      :ok <-
        unquote(unique_items_call)(
          item,
          accumulator.so_far,
          Path.join(path, "#{accumulator.index}")
        )
    end
  end

  defp filter_for({"prefixItems", _}, _, accumulator, authority, pointer, opts) do
    prefix_items_call = Tools.call(authority, JsonPointer.join(pointer, "prefixItems"), opts)

    quote do
      :ok <-
        unquote(prefix_items_call)(
          {item, unquote(index(accumulator))},
          Path.join(path, "#{unquote(index(accumulator))}")
        )
    end
  end

  defp filter_for({"contains", _}, _, accumulator, authority, pointer, opts) do
    # just a basic assertion here for safety
    :contains in accumulator or raise "contains without :contains in accumulator"
    contains_call = Tools.call(authority, JsonPointer.join(pointer, "contains"), opts)

    quote do
      new_contains =
        if :ok === unquote(contains_call)(item, Path.join(path, "#{accumulator.index}")),
          do: accumulator.contains + 1,
          else: accumulator.contains
    end
  end

  defp filter_for({"maxContains", _}, _, accumulator, authority, pointer, opts) do
    # just a basic assertion here for safety

    # NOTE THAT THIS FILTER must come after "contains" filter.
    :contains in accumulator or raise "maxContains without :contains in accumulator"

    max_contains_call = Tools.call(authority, JsonPointer.join(pointer, "maxContains"), opts)

    quote do
      :ok <-
        unquote(max_contains_call)(new_contains, array, Path.join(path, "#{accumulator.index}"))
    end
  end

  defp filter_for({"items", context}, _, accumulator, authority, pointer, opts)
       when is_map(context) or is_boolean(context) do
    # this requires an entry point
    items_call = Tools.call(authority, JsonPointer.join(pointer, ["items", ":entrypoint"]), opts)

    quote do
      :ok <-
        unquote(items_call)(
          {item, unquote(index(accumulator))},
          Path.join(path, "#{unquote(index(accumulator))}")
        )
    end
  end

  # TODO: items needs to be last.
  defp filter_for({"items", array}, _, accumulator, authority, pointer, opts)
       when is_list(array) do
    items_call = Tools.call(authority, JsonPointer.join(pointer, "items"), opts)

    quote do
      :ok <-
        unquote(items_call)(
          {item, unquote(index(accumulator))},
          Path.join(path, "#{unquote(index(accumulator))}")
        )
    end
  end

  defp filter_for({"additionalItems", _}, _, accumulator, authority, pointer, opts) do
    additional_items_call =
      Tools.call(authority, JsonPointer.join(pointer, ["additionalItems", ":entrypoint"]), opts)

    quote do
      :ok <-
        unquote(additional_items_call)(
          {item, unquote(index(accumulator))},
          Path.join(path, "#{unquote(index(accumulator))}")
        )
    end
  end

  defp filter_for({"unevaluatedItems", _}, context, accumulator, authority, pointer, opts) do
    additional_items_call =
      Tools.call(authority, JsonPointer.join(pointer, ["unevaluatedItems", ":entrypoint"]), opts)

    tuple_parts =
      cond do
        !passed_unseen_index?(context) ->
          quote do
            [item, unquote(index(accumulator))]
          end

        prefix = context["prefixItems"] ->
          length = length(prefix)

          quote do
            [item, unquote(index(accumulator)), max(first_unseen_index, unquote(length))]
          end

        true ->
          quote do
            [item, unquote(index(accumulator)), first_unseen_index]
          end
      end

    quote do
      :ok <-
        unquote(additional_items_call)(
          {unquote_splicing(tuple_parts)},
          Path.join(path, "#{unquote(index(accumulator))}")
        )
    end
  end

  defp filter_for(_, _, _, _, _, _), do: nil

  # TODO: minItems AND contains

  defp finalizer_for(subschema = %{"minItems" => min}, tracked, accumulators, pointer) do
    minitems_pointer = JsonPointer.join(pointer, "minItems")

    index =
      case accumulators do
        [] ->
          quote do
            accumulator
          end

        [_ | _] ->
          quote do
            accumulator.index
          end
      end

    quote do
      case do
        {error} ->
          error

        {:ok, accumulator} when unquote(index) < unquote(min) ->
          require Exonerate.Tools
          Exonerate.Tools.mismatch(array, unquote(minitems_pointer), path)

        {:ok, accumulator} ->
          unquote(finalizer_return(subschema, tracked, accumulators))
      end
    end
  end

  defp finalizer_for(subschema = %{"contains" => _}, tracked, accumulators, pointer) do
    contains_pointer = JsonPointer.join(pointer, "contains")
    mincontains_pointer = JsonPointer.join(pointer, "minContains")
    mincontains = Map.get(subschema, "minContains", 1)

    quote do
      case do
        {error} ->
          error

        {:ok, accumulator} when accumulator.contains == 0 ->
          require Exonerate.Tools
          Exonerate.Tools.mismatch(array, unquote(contains_pointer), path)

        {:ok, accumulator} when accumulator.contains < unquote(mincontains) ->
          require Exonerate.Tools
          Exonerate.Tools.mismatch(array, unquote(mincontains_pointer), path)

        {:ok, accumulator} ->
          unquote(finalizer_return(subschema, tracked, accumulators))
      end
    end
  end

  @accumulator (quote do
                  {:ok, accumulator}
                end)

  defp finalizer_for(subschema, tracked, accumulators, _) do
    finalizer_return = finalizer_return(subschema, tracked, accumulators)

    cond do
      !tracked ->
        quote do
          elem(0)
        end

      finalizer_return == @accumulator ->
        quote do
          case do
            {:ok, accumulator} -> unquote(finalizer_return)
            {error} -> error
          end
        end

      true ->
        quote do
          case do
            {:ok, accumulator} -> unquote(finalizer_return)
            error -> error
          end
        end
    end
  end

  defp finalizer_return(subschema, tracked, accumulators) do
    if tracked do
      cond do
        is_map_key(subschema, "additionalItems") or is_map_key(subschema, "unevaluatedItems") ->
          {:ok, index(accumulators)}

        is_map_key(subschema, "prefixItems") ->
          length = length(subschema["prefixItems"])

          min =
            quote do
              min(unquote(index(accumulators)), unquote(length))
            end

          {:ok, min}

        true ->
          {:ok, 0}
      end
    else
      :ok
    end
  end

  @filters Iterator.filters()

  defp accumulator(context) do
    context
    |> Map.take(@filters)
    |> Map.keys()
    |> Enum.flat_map(&accumulators_for/1)
    |> Enum.uniq()
  end

  defp accumulators_for("contains"), do: [:contains]
  defp accumulators_for("uniqueItems"), do: [:so_far]
  defp accumulators_for(_), do: []
end
