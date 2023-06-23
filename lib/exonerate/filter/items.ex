defmodule Exonerate.Filter.Items do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Degeneracy
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
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  def build_filter(context = %{"items" => false}, resource, pointer, opts) do
    bad_index =
      context
      |> Map.get("prefixItems", [])
      |> length

    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_pointer = JsonPtr.join(pointer, "items")

    termination_head =
      Iterator.select(
        context,
        quote do
          [
            array,
            [_ | _],
            path,
            unquote(bad_index),
            _contains_count,
            _first_unseen_index,
            _unique_items
          ]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(termination_head)) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(array, unquote(resource), unquote(items_pointer), path)
      end
    end
  end

  # the list form of items is technically supposed to be "prefixItems" but
  # it's still supported in newer versions of the spec.
  def build_filter(context = %{"items" => subschema}, resource, pointer, opts)
      when is_list(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    Enum.with_index(subschema, fn item_subschema, index ->
      items_call =
        Tools.call(
          resource,
          JsonPtr.join(pointer, ["items", "#{index}"]),
          Context.scrub_opts(opts)
        )

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

              case unquote(items_call)(item, Path.join(path, "#{unquote(index)}")) do
                :ok ->
                  unquote(iterator_call)(unquote_splicing(iteration_next))

                Exonerate.Tools.error_match(error) ->
                  error
              end
            end
          end
      end
    end)
  end

  # items which is now "additionalItems"; this is an object and is applied to
  # everything after prefixItems
  def build_filter(context = %{"items" => subschema}, resource, pointer, opts)
      when is_map(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    items_call = Tools.call(resource, JsonPtr.join(pointer, "items"), Context.scrub_opts(opts))

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

        case unquote(items_call)(item, Path.join(path, "#{index}")) do
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

      defp unquote(iterator_call)(unquote_splicing(terminator_head)) do
        :ok
      end
    end
  end

  def build_filter(_, _resource, _pointer, _opts), do: []

  defmacro context(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    opts = Context.scrub_opts(opts)

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_context(subschema, resource, pointer, opts)
       when is_map(subschema) or is_boolean(subschema) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
    end
  end

  defp build_context(subschema, resource, pointer, opts) when is_list(subschema) do
    Enum.with_index(subschema, fn _, index ->
      pointer = JsonPtr.join(pointer, "#{index}")

      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end)
  end
end
