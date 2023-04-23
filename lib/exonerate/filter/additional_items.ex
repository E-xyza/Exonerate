defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  # this is equivalent to the array form of "items"
  defp build_filter(context = %{"additionalItems" => false}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    additional_items_pointer = JsonPointer.join(pointer, "additionalItems")

    iteration_head =
      Iterator.select(
        context,
        quote do
          [array, [item | rest], path, index, _contains_count, _first_unseen_index, _unique_items]
        end
      )

    terminator_head =
      Iterator.select(
        context,
        quote do
          [_, [], _path, _index, _contains_count, _first_unseen_index, _unique_items]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          item,
          unquote(resource),
          unquote(additional_items_pointer),
          Path.join(path, "#{index}")
        )
      end

      defp unquote(iterator_call)(unquote_splicing(terminator_head)), do: :ok
    end
  end

  defp build_filter(context = %{"additionalItems" => subschema}, resource, pointer, opts)
       when is_map(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    items_call =
      Tools.call(resource, JsonPointer.join(pointer, "additionalItems"), Context.scrub_opts(opts))

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
          [_, [], _path, _index, _contains_count, _first_unseen_index, _unique_items]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
        require Exonerate.Tools

        require Exonerate.Filter.Contains
        require Exonerate.Filter.UniqueItems

        Exonerate.Filter.Contains.next_contains(
          unquote(resource),
          unquote(pointer),
          [contains_count, item, path],
          unquote(opts)
        )

        Exonerate.Filter.UniqueItems.next_unique(
          unquote(resource),
          unquote(pointer),
          unique_items,
          item,
          unquote(opts)
        )

        case unquote(items_call)(item, Path.join(path, "#{index}")) do
          :ok ->
            unquote(iterator_call)(unquote_splicing(iteration_next))

          Exonerate.Tools.error_match(error) ->
            error
        end
      end

      defp unquote(iterator_call)(unquote_splicing(terminator_head)) do
        :ok
      end
    end
  end

  defp build_filter(_, _, _, _), do: []

  defmacro context(resource, pointer, opts) do
    opts = Context.scrub_opts(opts)

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_context(false, _, _, _), do: []

  defp build_context(_context, resource, pointer, opts) do
    opts = Context.scrub_opts(opts)

    quote do
      require Exonerate.Context

      Exonerate.Context.filter(
        unquote(resource),
        unquote(pointer),
        unquote(opts)
      )
    end
  end
end
