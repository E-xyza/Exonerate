defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    parent_pointer = JsonPointer.backtrack!(pointer)
    __CALLER__
    |> Tools.subschema(authority, parent_pointer)
    |> build_filter(authority, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(parent = %{"prefixItems" => subschema}, authority, parent_pointer, opts) do
    pointer = JsonPointer.join(parent_pointer, "prefixItems")
    call = Tools.call(authority, pointer, opts)

    {calls, filters} =
      subschema
      |> Enum.with_index(&item_to_filter(&1, &2, authority, pointer, opts))
      |> Enum.unzip()

    additional_items = additional_items_for(parent, authority, parent_pointer, opts)

    quote do
      unquote(calls)
      defp unquote(call)(item, _index, path), do: unquote(additional_items)
      unquote(filters)
    end
  end

  defp item_to_filter(_, index, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    item_pointer = JsonPointer.join(pointer, "#{index}")
    item_call = Tools.call(authority, item_pointer, opts)

    {
      quote do
        defp unquote(call)(item, unquote(index), path) do
          unquote(item_call)(item, path)
        end
      end,
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(authority), unquote(item_pointer), unquote(opts))
      end
    }
  end

  defp additional_items_for(parent, authority, parent_pointer, opts) do
    case parent do
      %{"additionalItems" => _} ->
        additional_call = Tools.call(authority, parent_pointer, opts)
        quote do
          unquote(additional_call)(item, path)
        end

      _ ->
        :ok
    end
  end
end
