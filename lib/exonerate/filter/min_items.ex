defmodule Exonerate.Filter.MinItems do
  @moduledoc false

  # This module generates an iterator function

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context = %{"minItems" => minimum}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    minitems_pointer = JsonPointer.join(pointer, "minItems")

    filter_params =
      Iterator.select_params(
        context,
        quote do
          [array, [], index, path, first_unseen_index, unique]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(filter_params))
           when index < unquote(minimum) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(minitems_pointer), path)
      end
    end
  end

  defmacro find_filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_find_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_find_filter(context = %{"minItems" => min_items}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)
    min_items_pointer = JsonPointer.join(pointer, "minItems")

    terminator_params =
      Iterator.select_params(
        context,
        quote do
          [array, [], path, index, _]
        end
      )

    quote do
      defp unquote(call)(unquote_splicing(terminator_params)) when index < unquote(min_items) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(min_items_pointer), path)
      end
    end
  end

  defp build_find_filter(_, _, _, _), do: []
end
