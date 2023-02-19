defmodule Exonerate.Filter.Items do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    subschema = Cache.fetch!(name)
    items = JsonPointer.resolve!(subschema, pointer)

    prefix_items =
      subschema
      |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
      |> Map.get("prefixItems")
      |> List.wrap()
      |> length

    Tools.maybe_dump(
      case items do
        items when (is_map(items) or is_boolean(items)) and prefix_items == 0 ->
          quote do
            require Exonerate.Context
            Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
          end

        items when is_map(items) or is_boolean(items) ->
          call = Tools.pointer_to_fun_name(pointer, authority: name)

          quote do
            defp unquote(call)(item, index, path) when index < unquote(prefix_items),
              do: :ok

            defp unquote(call)(item, _index, path) do
              unquote(call)(item, path)
            end

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

          additional_items = additional_items_for(name, pointer, opts)

          quote do
            unquote(calls)
            defp unquote(call)(item, _index, path), do: unquote(additional_items)
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

  defp additional_items_for(name, pointer, _opts) do
    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
    |> case do
      %{"additionalItems" => _} ->
        additional_call =
          pointer
          |> JsonPointer.backtrack!()
          |> JsonPointer.traverse("additionalItems")
          |> Tools.pointer_to_fun_name(authority: name)

        quote do
          unquote(additional_call)(item, path)
        end

      _ ->
        :ok
    end
  end
end
