defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    IO.puts(IO.ANSI.red() <> "===============================" <> IO.ANSI.reset())

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> IO.inspect()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # this is equivalent to the array form of "items"
  defp build_filter(%{"additionalItems" => false}, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    additional_items_pointer = JsonPointer.join(pointer, "additionalItems")

    quote do
      defp unquote(iterator_call)(_, [], _, _), do: :ok

      defp unquote(iterator_call)(array, [item | _], index, path) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          item,
          unquote(resource),
          unquote(additional_items_pointer),
          Path.join(path, "#{index}")
        )
      end
    end
  end

  defp build_filter(%{"additionalItems" => subschema}, resource, pointer, opts)
       when is_map(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "additionalItems"), opts)

    quote do
      defp unquote(iterator_call)(array, [item | rest], index, path) do
        require Exonerate.Tools

        case unquote(items_call)(item, Path.join(path, "#{index}")) do
          :ok ->
            unquote(iterator_call)(array, rest, index + 1, path)

          Exonerate.Tools.error_match(error) ->
            error
        end
      end

      defp unquote(iterator_call)(_, [], index, path) do
        :ok
      end
    end
  end

  defp build_filter(_, _, _, _), do: []

  defmacro context(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(false, _, _, _), do: []

  defp build_context(_context, resource, pointer, opts) do
    opts = Tools.scrub(opts)

    quote do
      require Exonerate.Context

      Exonerate.Context.filter(
        unquote(resource),
        unquote(pointer),
        unquote(opts)
      )
    end
  end
end
