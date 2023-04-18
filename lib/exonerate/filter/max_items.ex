defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  # NOTE this generates an iterator function

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, JsonPointer.join(pointer, "maxItems"))
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(limit, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    maxitems_pointer = JsonPointer.join(pointer, "maxItems")

    quote do
      defp unquote(iterator_call)(array, _, index, path) when index >= unquote(limit) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(maxitems_pointer), path)
      end
    end
  end
end
