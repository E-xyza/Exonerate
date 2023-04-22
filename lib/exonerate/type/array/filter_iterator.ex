defmodule Exonerate.Type.Array.FilterIterator do
  @moduledoc false

  # macros for "filter-mode" array filtering.  This is for cases when rejecting
  # the array occurs when a single item fails with error, this is distinct from
  # when the accepting the array occurs when a single item passes with :ok.
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
  # - index
  #
  # the following call parameters are loaded to the end of the params
  # if their respective filters exists
  #
  # - "contains" -> contains_count
  # - "unevaluatedParameters" -> first_unseen_index
  # - "unique" -> unique_items

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_iterator(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_iterator(context, resource, pointer, opts) do
    quote do
      unquote(guard_iterators(context, resource, pointer, opts))
      # the items filter is special-cased at the top because it can both be a guard iterator
      # and a default iterator
      require Exonerate.Filter.Items
      Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.Contains
      Exonerate.Filter.Contains.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.PrefixItems
      Exonerate.Filter.PrefixItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.AdditionalItems
      Exonerate.Filter.AdditionalItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.UnevaluatedItems
      Exonerate.Filter.UnevaluatedItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Type.Array.FilterIterator

      Exonerate.Type.Array.FilterIterator.default_filter(
        unquote(resource),
        unquote(pointer),
        unquote(opts)
      )
    end
  end

  defp guard_iterators(context, resource, pointer, opts) do
    Enum.flat_map(context, fn
      {"maxItems", _} ->
        [
          quote do
            require Exonerate.Filter.MaxItems
            Exonerate.Filter.MaxItems.filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        ]

      {"minItems", _} ->
        [
          quote do
            require Exonerate.Filter.MinItems
            Exonerate.Filter.MinItems.filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        ]

      {"uniqueItems", _} ->
        [
          quote do
            require Exonerate.Filter.UniqueItems

            Exonerate.Filter.UniqueItems.filter(
              unquote(resource),
              unquote(pointer),
              unquote(opts)
            )
          end
        ]

      _ ->
        []
    end)
  end

  # - full array
  # - remaining array
  # - path
  # - index
  #
  # the following call parameters are loaded to the end of the params
  # if their respective filters exists
  #
  # - "contains" -> contains_count
  # - "unevaluatedParameters" -> first_unseen_index
  # - "unique" -> unique_items

  # allows to select which parameters are looked at in the iterator, based on the context
  def select(context, [array, array_so_far, path, index, contains_count, unevaluated, unique_items]) do
    [array, array_so_far, index, path] ++
      List.wrap(if Map.has_key?(context, "contains"), do: contains_count) ++
      List.wrap(if needs_unseen_index?(context), do: unevaluated) ++
      List.wrap(if Map.get(context, "uniqueItems"), do: unique_items)
  end

  @seen_keys ~w(allOf anyOf if oneOf dependentSchemas $ref)
  def needs_unseen_index?(context = %{"unevaluatedItems" => _}) do
    Enum.any?(@seen_keys, &is_map_key(context, &1))
  end

  def needs_unseen_index?(_), do: false

  defmacro default_filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    iteration_head =
      Iterator.select(
        context,
        quote do
          [array, [item | rest], path, index, contains_count, first_unseen_index, unique_items]
        end
      )

    iteration_next =
      Iterator.select(
        context,
        quote do
          [array, rest, path, index + 1, contains_count, first_unseen_index, unique_items]
        end
      )

    terminator_head =
      Iterator.select(
        context,
        quote do
          [_array, [], _path, _index, _contains_count, _first_unseen_index, _unique_items]
        end
      )

    List.wrap(
      if needs_default_terminator(context) do
        quote do
          defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
            require Exonerate.Filter.UniqueItems

            Exonerate.Filter.UniqueItems.next_unique(
              unquote(resource),
              unquote(pointer),
              unique_items,
              item,
              unquote(opts)
            )

            unquote(iterator_call)(unquote_splicing(iteration_next))
          end

          defp unquote(iterator_call)(unquote_splicing(terminator_head)), do: :ok
        end
      end
    )
  end

  defp needs_default_terminator(%{"additionalItems" => _}), do: false
  defp needs_default_terminator(%{"unevaluatedItems" => _}), do: false
  defp needs_default_terminator(%{"items" => %{}}), do: false
  defp needs_default_terminator(_), do: true
end
