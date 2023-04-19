defmodule Exonerate.Filter.MinContains do
  @moduledoc false

  alias Exonerate.Tools

  defmacro find_filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_find_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_find_filter(context, resource, pointer, opts) do
    # call = Iterator.call(resource, pointer, opts)
    # min_items_pointer = JsonPointer.join(pointer, "minItems")
    # terminator_params =
    #  Iterator.select_params(
    #    context,
    #    quote do
    #      [array, [], path, _index, _]
    #    end,
    #    opts
    #  )
    #
    quote do
    end
  end
end
