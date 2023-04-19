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
          [_, [], _index, _path, _, _]
        end,
        opts
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(iteration_head)) do
        require Exonerate.Tools
        require Exonerate.Filter.UniqueItems

        Exonerate.Filter.UniqueItems.next_unique(
          unquote(resource),
          unquote(pointer),
          unique,
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
  # it's supposed to be supported in newer versions of the spec.
  def build_filter(context = %{"items" => subschema}, resource, pointer, opts)
      when is_list(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    Enum.with_index(subschema, fn _, index ->
      items_call = Tools.call(resource, JsonPointer.join(pointer, ["items", "#{index}"]), opts)

      iteration_head =
        Iterator.select_params(
          context,
          quote do
            [array, [item | rest], unquote(index), path, first_unseen_index, unique]
          end,
          opts
        )

      iteration_next =
        Iterator.select_params(
          context,
          quote do
            [array, rest, unquote(index + 1), path, first_unseen_index, unique]
          end,
          opts
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
end
