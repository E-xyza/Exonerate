defmodule Exonerate.Filter.MinContains do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro find_filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_find_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_find_filter(context = %{"minContains" => min_contains}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    terminal_params =
      Iterator.select_params(
        context,
        quote do
          [array, [], path, _index, contains_count]
        end
      )

    min_contains_pointer = JsonPointer.join(pointer, "minContains")

    quote do
      defp unquote(call)(unquote_splicing(terminal_params))
           when contains_count < unquote(min_contains) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(min_contains_pointer), path)
      end
    end
  end

  defp build_find_filter(_, _, _, _), do: []
end
