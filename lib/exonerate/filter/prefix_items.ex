defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  alias Exonerate.Degeneracy
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context = %{"prefixItems" => subschema}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    Enum.with_index(subschema, fn item_subschema, index ->
      items_call =
        Tools.call(resource, JsonPointer.join(pointer, ["prefixItems", "#{index}"]), opts)

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

      case Degeneracy.class(item_subschema) do
        :ok ->
          quote do
            defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
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

              unquote(iterator_call)(unquote_splicing(iteration_next))
            end
          end

        :error ->
          quote do
            defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
              unquote(items_call)(item, Path.join(path, "#{unquote(index)}"))
            end
          end

        :unknown ->
          quote do
            defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
              require Exonerate.Tools

              case unquote(items_call)(item, Path.join(path, "#{unquote(index)}")) do
                :ok ->
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

                  unquote(iterator_call)(unquote_splicing(iteration_next))

                Exonerate.Tools.error_match(error) ->
                  error
              end
            end
          end
      end
    end)
  end

  defp build_filter(_, _, _, _), do: []

  defmacro context(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(subschema, resource, pointer, opts) do
    Enum.with_index(subschema, fn _, index ->
      pointer = JsonPointer.join(pointer, "#{index}")

      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end)
  end
end
