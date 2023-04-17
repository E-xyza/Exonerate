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
      # the items filter is ALWAYS called.
      require Exonerate.Filter.Items
      Exonerate.Filter.Items.filter(unquote(resource), unquote(pointer), unquote(opts))
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
end
