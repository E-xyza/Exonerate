defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

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

    Enum.with_index(subschema, fn _, index ->
      items_call =
        Tools.call(resource, JsonPointer.join(pointer, ["prefixItems", "#{index}"]), opts)

      iteration_head =
        Iterator.select_params(
          context,
          quote do
            [array, [item | rest], path, unquote(index), first_unseen_index, unique]
          end
        )

      iteration_next =
        Iterator.select_params(
          context,
          quote do
            [array, rest, path, unquote(index + 1), first_unseen_index, unique]
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
