defmodule Exonerate.Filter.Contains do
  @moduledoc false

  # NOTE this generates an iterator function

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

  # if there's a minContains filter, don't create the find filter
  defp build_find_filter(%{"minContains" => _}, _, _, _), do: []

  defp build_find_filter(context = %{"contains" => _}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    terminal_params =
      Iterator.select_params(
        context,
        quote do
          [array, [], path, _index, _]
        end,
        opts
      )

    contains_pointer = JsonPointer.join(pointer, "contains")

    quote do
      defp unquote(call)(unquote_splicing(terminal_params)) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(contains_pointer), path)
      end
    end
  end

  defp build_find_filter(_, _, _, _), do: []

  defmacro context(resource, pointer, opts) do
    resource
    |> build_context(pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(resource, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(Tools.scrub(opts)))
    end
  end
end
