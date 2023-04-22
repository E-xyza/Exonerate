defmodule Exonerate.Filter.Items do
  @moduledoc false
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  # NOTE this generates an iterator function
  # !! important this generator gets called regardless of if the items property
  # is present in the subschema object

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # items which is now "additionalItems"
  def build_filter(context = %{"items" => subschema}, resource, pointer, opts)
      when is_map(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "items"), opts)

    iteration_head =
      Iterator.select(
        context,
        quote do
          [array, [item | rest], path, index, contains_index, first_unseen_index, unique_items]
        end
      )

    iteration_next =
      Iterator.select(
        context,
        quote do
          [array, rest, path, index + 1, contains_index, first_unseen_index, unique_items]
        end
      )

    terminator_head =
      Iterator.select(
        context,
        quote do
          [_, [], _path, _index, _contains_index, _first_unseen_index, _unique_items]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
        require Exonerate.Tools
        require Exonerate.Filter.UniqueItems

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

  # the list form of items is technically supposed to be "prefixItems" but
  # it's still supported in newer versions of the spec.
  def build_filter(context = %{"items" => subschema}, resource, pointer, opts)
      when is_list(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    Enum.with_index(subschema, fn _, index ->
      items_call = Tools.call(resource, JsonPointer.join(pointer, ["items", "#{index}"]), opts)

      iteration_head =
        Iterator.select(
          context,
          quote do
            [
              array,
              [item | rest],
              path,
              unquote(index),
              contains_count,
              first_unseen_index,
              unique_items
            ]
          end
        )

      iteration_next =
        Iterator.select(
          context,
          quote do
            [
              array,
              rest,
              path,
              unquote(index + 1),
              contains_count,
              first_unseen_index,
              unique_items
            ]
          end
        )

      quote do
        defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
          require Exonerate.Tools

          case unquote(items_call)(item, Path.join(path, "#{unquote(index)}")) do
            :ok ->
              unquote(iterator_call)(unquote_splicing(iteration_next))

            Exonerate.Tools.error_match(error) ->
              error
          end
        end
      end
    end)
  end

  def build_filter(_, _resource, _pointer, _opts), do: []

  defmacro context(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(subschema, resource, pointer, opts) when is_map(subschema) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
    end
  end

  defp build_context(subschema, resource, pointer, opts) when is_list(subschema) do
    Enum.with_index(subschema, fn _, index ->
      pointer = JsonPointer.join(pointer, "#{index}")

      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end)
  end

  defp build_context(_, _, _, _), do: []
end
