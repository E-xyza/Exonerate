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
  # - array looked at so far
  # - index
  # - path
  #
  # the following call parameters are loaded to the end of the params
  # if their respective filters exists
  #
  # - "unevaluatedParameters" -> unevaluated_index
  # - "unique" -> unique

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_iterator(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def params(context, _resource, _pointer, _opts) do
    [:array, :array, 0, :path] ++
      List.wrap(if is_map_key(context, "unevaluatedParameters"), do: :first_unseen_index) ++
      List.wrap(if is_map_key(context, "uniqueItems"), do: :unique)
  end

  defp build_iterator(context, resource, pointer, opts) do
    quote do
      unquote(guard_iterators(context, resource, pointer, opts))
      # the items filter is special-cased at the top because it can both be a guard iterator
      # and a default iterator
      require Exonerate.Filter.Items
      Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.AdditionalItems
      Exonerate.Filter.AdditionalItems.filter(unquote(resource), unquote(pointer), unquote(opts))

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
            Exonerate.Filter.UniqueItems.filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        ]

      _ ->
        []
    end)
  end

  # allows to select which parameters are looked at in the iterator, based on the context
  def select_params(%{"unevaluatedItems" => _, "uniqueItems" => _}, [
        array,
        array_so_far,
        index,
        path,
        unevaluated,
        unique
      ]) do
    [array, array_so_far, index, path, unevaluated, unique]
  end

  def select_params(%{"unevaluatedItems" => _}, [array, array_so_far, index, path, unevaluated, _]) do
    [array, array_so_far, index, path, unevaluated]
  end

  def select_params(%{"uniqueItems" => _}, [array, array_so_far, index, path, _, unique]) do
    [array, array_so_far, index, path, unique]
  end

  def select_params(_, [array, array_so_far, index, path, _, _]) do
    [array, array_so_far, index, path]
  end

  defmacro default_filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    iteration_head =
      Iterator.select_params(
        context,
        quote do
          [array, [item | rest], index, path, first_unseen_index, unique]
        end,
        opts
      )

    iteration_next =
      Iterator.select_params(
        context,
        quote do
          [array, rest, index + 1, path, first_unseen_index, unique]
        end,
        opts
      )

    terminator_head =
      Iterator.select_params(
        context,
        quote do
          [_array, [], _index, _path, _, _]
        end,
        opts
      )

    List.wrap(
      if needs_default_terminator(context) do
        quote do
          defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
            require Exonerate.Filter.UniqueItems

            Exonerate.Filter.UniqueItems.next_unique(
              unquote(resource),
              unquote(pointer),
              unique,
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
