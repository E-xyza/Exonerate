defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  # NOTE this generates an iterator function

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

  defp build_filter(context = %{"maxItems" => limit}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    maxitems_pointer = JsonPointer.join(pointer, "maxItems")

    # note that this has to be index > limit, because there will be an iteration with the
    # empty list when the index equals the limit.

    filter_params =
      Iterator.select(
        context,
        quote do
          [array, _, path, index, _contains_count, _first_unseen_index, _unique_items]
        end
      )

    quote do
      defp unquote(iterator_call)(unquote_splicing(filter_params)) when index > unquote(limit) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(maxitems_pointer), path)
      end
    end
  end
end
