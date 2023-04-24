defmodule Exonerate.Type.Array.FindIterator do
  @moduledoc false

  # macros for "find-mode" array filtering.  This is for cases when accepting
  # the array occurs when a single item passes with :ok, this is distinct from
  # when the rejecting the array occurs when a single item fails with error.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1
  #
  # The iterator for this function can have different number of call parameters
  # depending on which filters the context applies.  The following call parameters
  # are ALWAYS present:
  #
  # - full array
  # - remaining array
  # - path
  #
  # the following call parameters are loaded to the end of the params
  # if their respective filters exists
  #
  # - "minItems" -> index
  # - "Items" (array) / "prefixItems" -> index
  # - "minContains" / "contains" -> contains_count

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_iterator(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp needs_index?(%{"minItems" => _}), do: true
  defp needs_index?(%{"prefixItems" => _}), do: true
  defp needs_index?(%{"items" => list}) when is_list(list), do: true
  defp needs_index?(_), do: false

  # at its core, the iterator is a reduce-while that encapsulates a with
  # statement.  The reduce-while operates over the entire array, and halts when
  # :ok is encountered.

  # note that there are only three cases for this mode to be activated, and
  # we're going to write out each of these cases by hand.

  defp build_iterator(_context, resource, pointer, opts) do
    quote do
      # the following filters encode terminal conditions
      require Exonerate.Filter.MinItems
      Exonerate.Filter.MinItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.MinContains
      Exonerate.Filter.MinContains.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.Contains
      Exonerate.Filter.Contains.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.PrefixItems
      Exonerate.Filter.PrefixItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.Items
      Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Type.Array.FindIterator

      Exonerate.Type.Array.FindIterator.default_filter(
        unquote(resource),
        unquote(pointer),
        unquote(opts)
      )
    end
  end

  defmacro default_filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_default_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  def build_default_filter(context, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    head_params =
      Iterator.select(
        context,
        quote do
          [array, [item | rest], path, index, contains_count, first_unseen_index, unique_items]
        end
      )

    next_params =
      Iterator.select(
        context,
        quote do
          [array, rest, path, index + 1, contains_count, first_unseen_index, unique_items]
        end
      )

    end_params =
      Iterator.select(
        context,
        quote do
          [array, [], path, index, contains_count, _first_unseen_index, _unique_items]
        end
      )

    quote do
      defp unquote(call)(unquote_splicing(head_params)) do
        Exonerate.Filter.Contains.next_contains(
          unquote(resource),
          unquote(pointer),
          [contains_count, item, path],
          unquote(opts)
        )

        unquote(call)(unquote_splicing(next_params))
      end

      defp unquote(call)(unquote_splicing(end_params)) do
        :ok
      end
    end
  end

  # allows to select which parameters are looked at in the iterator, based on the context
  def select(context, [
        array,
        array_so_far,
        path,
        index,
        contains_count,
        _unevaluated,
        _unique_items
      ]) do
    [array, array_so_far, path] ++
      List.wrap(if needs_index?(context), do: index) ++
      List.wrap(if is_map_key(context, "contains"), do: contains_count)
  end
end
