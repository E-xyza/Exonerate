defmodule Exonerate.Filter.MaxContains do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(context = %{"maxContains" => max_contains}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    terminal_params =
      Iterator.select(
        context,
        quote do
          [array, _, path, _index, contains_count, _first_unseen_index, _unique_items]
        end
      )

    max_contains_pointer = JsonPtr.join(pointer, "maxContains")

    quote do
      defp unquote(call)(unquote_splicing(terminal_params))
           when contains_count > unquote(max_contains) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(max_contains_pointer), path)
      end
    end
  end

  defp build_filter(_, _, _, _), do: []
end
