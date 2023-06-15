defmodule Exonerate.Filter.MinContains do
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

  defp build_filter(context = %{"minContains" => min_contains}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    terminal_params =
      Iterator.select(
        context,
        quote do
          [array, [], path, _index, contains_count, _first_unseen_index, _unique_items]
        end
      )

    min_contains_pointer = JsonPtr.join(pointer, "minContains")

    quote do
      defp unquote(call)(unquote_splicing(terminal_params))
           when contains_count < unquote(min_contains) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(min_contains_pointer), path)
      end
    end
  end

  defp build_filter(_, _, _, _), do: []
end
