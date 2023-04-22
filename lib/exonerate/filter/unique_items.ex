defmodule Exonerate.Filter.UniqueItems do
  @moduledoc false

  # This module generates an iterator function

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro initialize(_opts) do
    # TODO:
    # if use_xor_filter is set to false, then fall back on MapSet.new
    quote do
      MapSet.new()
    end
  end

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # note that if uniqueItems is false, it will get eliminated at at the stage of
  defp build_filter(context = %{"uniqueItems" => true}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    minitems_pointer = JsonPointer.join(pointer, "uniqueItems")

    failure_params =
      Iterator.select(
        context,
        quote do
          [array, _, path, _index, _contains_count, _first_unseen_index, false]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(failure_params)) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(minitems_pointer), path)
      end
    end
  end

  defmacro next_unique(resource, pointer, unique_items, item, _opts) do
    # TODO: let this be generalizable to xor_filter
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> case do
      %{"uniqueItems" => true} ->
        quote do
          unquote(unique_items) =
            unquote(unique_items) === true or
              if MapSet.member?(unquote(unique_items), unquote(item)),
                do: false,
                else: MapSet.put(unquote(unique_items), unquote(item))
        end

      _ ->
        []
    end
  end

  defp build_filter(_, _, _, _), do: []
end
