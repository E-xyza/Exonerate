defmodule Exonerate.Type.Array.Filter do
  @moduledoc false

  # macros for "filter-mode" array filtering.  This is for cases when rejecting
  # the array occurs when a single item fails with error, this is distinct from
  # when the accepting the array occurs when a single item passes with :ok.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro iterator(authority, pointer, opts) do
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
    finalizer = finalizer_for(context, accumulator, pointer)

    quote do
      defp unquote(call)(array, path) do
        Enum.reduce_while(array, {:ok, unquote(init(accumulator))}, fn
          item, {:ok, accumulator} ->
            unquote(with_statement(context, accumulator, authority, pointer, opts))
        end)
        |> unquote(finalizer)
      end
    end
  end

  # SNIPPETS

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
      {:contains, accumulator.contains + if(contained, do: 1, else: 0)}
    end
  end

  # CODE BLOCKS

  defp with_statement(context, accumulator, authority, pointer, opts) do
    filters = Enum.flat_map(context, &filters_for(&1, accumulator, authority, pointer, opts))

    quote do
      with unquote_splicing(filters) do
        {:cont, {:ok, unquote(next(accumulator))}}
      else
        error = {:error, _} -> {:halt, {error}}
      end
    end
  end

  defp filters_for({"maxItems", _}, accumulator, authority, pointer, opts) do
    max_items_call = Tools.call(authority, JsonPointer.join(pointer, "maxItems"), opts)

    [
      quote do
        :ok <- unquote(max_items_call)(array, unquote(index(accumulator)), path)
      end
    ]
  end

  defp filters_for({"uniqueItems", true}, accumulator, authority, pointer, opts) do
    # just a basic assertion here for safety
    :so_far in accumulator or raise "uniqueItems without :so_far in accumulator"

    unique_items_call = Tools.call(authority, JsonPointer.join(pointer, "uniqueItems"), opts)

    [
      quote do
        :ok <-
          unquote(unique_items_call)(
            item,
            accumulator.so_far,
            Path.join(path, "#{accumulator.index}")
          )
      end
    ]
  end

  defp filters_for({"contains", _}, accumulator, authority, pointer, opts) do
    # just a basic assertion here for safety
    :contains in accumulator or raise "contains without :contains in accumulator"
    contains_call = Tools.call(authority, JsonPointer.join(pointer, "contains"), opts)

    [
      quote do
        contained = :ok === unquote(contains_call)(item, Path.join(path, "#{accumulator.index}"))
      end
    ]
  end

  defp filters_for({"items", object}, accumulator, authority, pointer, opts)
       when is_map(object) do
    items_call = Tools.call(authority, JsonPointer.join(pointer, "items"), opts)

    [
      quote do
        :ok <- unquote(items_call)(item, Path.join(path, "#{unquote(index(accumulator))}"))
      end
    ]
  end

  defp filters_for({"items", array}, accumulator, authority, pointer, opts) when is_list(array) do
    items_call = Tools.call(authority, JsonPointer.join(pointer, "items"), opts)

    [
      quote do
        :ok <-
          unquote(items_call)(
            {item, unquote(index(accumulator))},
            Path.join(path, "#{unquote(index(accumulator))}")
          )
      end
    ]
  end

  defp filters_for(_, _, _, _, _), do: []

  defp finalizer_for(%{"minItems" => min}, accumulator, pointer) do
    minitems_pointer = JsonPointer.join(pointer, "minItems")

    index =
      case accumulator do
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
          :ok
      end
    end
  end

  defp finalizer_for(_, _, _) do
    quote do
      elem(0)
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
