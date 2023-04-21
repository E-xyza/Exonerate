defmodule Exonerate.Filter.UnevaluatedItems do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  @seen_filters ~w(allOf anyOf if oneOf dependentSchemas $ref)

  defp build_filter(context, resource, pointer, opts) do
    if Enum.any?(@seen_filters, &is_map_key(context, &1)) do
      build_combining(context, resource, pointer, opts)
    else
      build_trivial(context, resource, pointer, opts)
    end
  end

  defp build_combining(context = %{"unevaluatedItems" => _}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "unevaluatedItems"), opts)

    iteration_head =
      Iterator.select_params(
        context,
        quote do
          [array, [item | rest], path, index, first_unseen_index, unique]
        end
      )

    iteration_next =
      Iterator.select_params(
        context,
        quote do
          [array, rest, path, index + 1, first_unseen_index, unique]
        end
      )

    terminator_head =
      Iterator.select_params(
        context,
        quote do
          [_, [], _path, _index, _, _]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(iteration_head))
           when index >= first_unseen_index do
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

  defp build_combining(_, _, _, _), do: []

  defp build_trivial(context = %{"unevaluatedItems" => _}, resource, pointer, opts) do
    # this is identical to the "additionalItems" result.

    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "unevaluatedItems"), opts)

    iteration_head =
      Iterator.select_params(
        context,
        quote do
          [array, [item | rest], path, index, first_unseen_index, unique]
        end
      )

    iteration_next =
      Iterator.select_params(
        context,
        quote do
          [array, rest, path, index + 1, first_unseen_index, unique]
        end
      )

    terminator_head =
      Iterator.select_params(
        context,
        quote do
          [_, [], _path, _index, _, _]
        end
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

  defp build_trivial(_, _, _, _), do: []

  # this is identical to additionalItems

  defmacro context(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(_context, resource, pointer, opts) do
    opts = Tools.scrub(opts)

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
