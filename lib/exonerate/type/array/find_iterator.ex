defmodule Exonerate.Type.Array.FindIterator do
  @moduledoc false

  # macros for "find-mode" array filtering.  This is for cases when accepting
  # the array occurs when a single item passes with :ok, this is distinct from
  # when the rejecting the array occurs when a single item fails with error.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1
  #
  # In order to be selected for "find mode", it should contain only the following
  # filters:
  #
  # - "minItems"
  # - "contains"
  # - "minContains"
  # - "items" (array)
  # - "prefixItems"
  #
  # The iterator for this function can have different number of call parameters
  # depending on which filters the context applies.  The following call parameters
  # are ALWAYS present:
  #
  # - full array
  # - array looked at so far
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
    |> Tools.maybe_dump(opts)
  end

  def args(context, _opts) do
    # includes "contains count"
    [:array, :array, :path] ++
      List.wrap(if needs_index?(context), do: 0) ++
      List.wrap(if is_map_key(context, "contains"), do: 0)
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
      # the items filter is special-cased at the top because it can be a filter iterator

      # require Exonerate.Filter.Items
      # Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))

      # the following filters encode terminal conditions
      require Exonerate.Filter.MinItems
      Exonerate.Filter.MinItems.find_filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.MinContains
      Exonerate.Filter.MinContains.find_filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.Contains
      Exonerate.Filter.Contains.find_filter(unquote(resource), unquote(pointer), unquote(opts))

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
    |> Tools.maybe_dump(opts)
  end

  def build_default_filter(context, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    head_params =
      quote do
        [array, [_ | rest], path, index, contains_count]
      end

    next_params =
      quote do
        [array, rest, path, index + 1, contains_count]
      end

    end_params =
      quote do
        [array, [], path, index, contains_count]
      end

    quote do
      defp unquote(call)(unquote_splicing(select_params(context, head_params))) do
        if unquote(success_condition(context)) do
          :ok
        else
          unquote(call)(unquote_splicing(select_params(context, next_params)))
        end
      end

      defp unquote(call)(unquote_splicing(select_params(context, end_params))) do
        :ok
      end
    end
  end

  def success_condition(context) do
    case context do
      %{"minItems" => items, "minContains" => min_contains} ->
        quote do
          index >= unquote(items) and contains_count >= unquote(min_contains)
        end

      %{"minItems" => items, "contains" => _} ->
        quote do
          index >= unquote(items) and contains_count >= 1
        end

      %{"minItems" => items} ->
        quote do
          index >= unquote(items)
        end

      %{"minContains" => min_contains} ->
        quote do
          contains_count >= unquote(min_contains)
        end

      %{"contains" => _} ->
        quote do
          contains_count >= 1
        end

      %{"items" => items} ->
        length = length(items)

        quote do
          index >= unquote(length)
        end

      %{"prefixItems" => items} ->
        length = length(items)

        quote do
          index >= unquote(length)
        end
    end
  end

  # allows to select which parameters are looked at in the iterator, based on the context
  def select_params(context, [array, array_so_far, path, index, contains_count]) do
    [array, array_so_far, path] ++
      List.wrap(if needs_index?(context), do: index) ++
      List.wrap(if is_map_key(context, "contains"), do: contains_count)
  end
end
