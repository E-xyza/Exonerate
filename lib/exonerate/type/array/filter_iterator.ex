defmodule Exonerate.Type.Array.FilterIterator do
  @moduledoc false

  # macros for "filter-mode" array filtering.  This is for cases when rejecting
  # the array occurs when a single item fails with error, this is distinct from
  # when the accepting the array occurs when a single item passes with :ok.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_iterator(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def params(_context, _resource, _pointer, _opts) do
    [:array, :array, 0, :path]
  end

  defp build_iterator(context, resource, pointer, opts) do
    quote do
      unquote(guard_iterators(context, resource, pointer, opts))
      # the items filter is special-cased at the top because it can both be a guard iterator
      # and a default iterator
      require Exonerate.Filter.Items
      Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Filter.AdditionalItems
      Exonerate.Filter.AdditionalItems.filter(unquote(resource), unquote(pointer), unquote(opts))

      require Exonerate.Type.Array.FilterIterator

      Exonerate.Type.Array.FilterIterator.default_filter(
        unquote(resource),
        unquote(pointer),
        unquote(opts)
      )
    end
  end

  defp guard_iterators(context, resource, pointer, opts) do
    Enum.flat_map(context, fn
      {"maxItems", _} ->
        [
          quote do
            require Exonerate.Filter.MaxItems
            Exonerate.Filter.MaxItems.filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        ]

      {"minItems", _} ->
        [
          quote do
            require Exonerate.Filter.MinItems
            Exonerate.Filter.MinItems.filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        ]

      _ ->
        []
    end)
  end

  defmacro default_filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    case Map.take(context, ~w(items additionalItems unevaluatedItems)) do
      map when map_size(map) === 0 ->
        quote do
          defp unquote(iterator_call)(array, [item | rest], index, path) do
            unquote(iterator_call)(array, rest, index + 1, path)
          end

          defp unquote(iterator_call)(array, [], index, path), do: :ok
        end

      _ ->
        []
    end
  end
end
