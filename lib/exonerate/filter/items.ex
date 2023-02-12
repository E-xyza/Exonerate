defmodule Exonerate.Filter.Items do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    items =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      case items do
        items when is_map(items) ->
          quote do
            require Exonerate.Context
            Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
          end

        # legacy "items" which is now prefixItems
        items when is_list(items) ->
          call = Tools.pointer_to_fun_name(pointer, authority: name)

          {calls, filters} =
            items
            |> Enum.with_index(&item_to_filter(&1, &2, name, pointer, opts))
            |> Enum.unzip()

          quote do
            unquote(calls)
            # items beyond the index items index, will support additionalItems later.
            defp unquote(call)(_item, _index, _pointer), do: :ok
            unquote(filters)
          end
      end,
      opts
    )
  end

  defp item_to_filter(_, index, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    item_pointer = JsonPointer.traverse(pointer, "#{index}")
    item_call = Tools.pointer_to_fun_name(item_pointer, authority: name)

    {
      quote do
        defp unquote(call)(item, unquote(index), path) do
          unquote(item_call)(item, path)
        end
      end,
      quote do
        require Exonerate.Context
        Exonerate.Context.from_cached(unquote(name), unquote(item_pointer), unquote(opts))
      end
    }
  end
end
