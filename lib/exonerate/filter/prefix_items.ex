defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    module = __CALLER__.module

    items =
      module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve_json!(pointer)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    {calls, filters} =
      items
      |> Enum.with_index(&item_to_filter(&1, &2, name, pointer, opts))
      |> Enum.unzip()

    additional_items = additional_items_for(module, name, pointer, opts)

    code =
      quote do
        unquote(calls)
        defp unquote(call)(item, _index, path), do: unquote(additional_items)
        unquote(filters)
      end

    Tools.maybe_dump(code, opts)
  end

  defp item_to_filter(_, index, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    item_pointer = JsonPointer.join(pointer, "#{index}")
    item_call = Tools.pointer_to_fun_name(item_pointer, authority: name)

    {
      quote do
        defp unquote(call)(item, unquote(index), path) do
          unquote(item_call)(item, path)
        end
      end,
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(name), unquote(item_pointer), unquote(opts))
      end
    }
  end

  defp additional_items_for(module, name, pointer, _opts) do
    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve_json!(JsonPointer.backtrack!(pointer))
    |> case do
      %{"additionalItems" => _} ->
        additional_call =
          pointer
          |> JsonPointer.backtrack!()
          |> JsonPointer.join("additionalItems")
          |> Tools.pointer_to_fun_name(authority: name)

        quote do
          unquote(additional_call)(item, path)
        end

      _ ->
        :ok
    end
  end
end
