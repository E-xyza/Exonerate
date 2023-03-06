defmodule Exonerate.Filter.Items do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(__CALLER__, authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(subschema, _caller, authority, pointer, opts)
       when is_map(subschema) or is_boolean(subschema) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end

  # legacy "items" which is now prefixItems
  defp build_filter(subschema, caller, authority, pointer, opts) when is_list(subschema) do
    # TODO: warn if the schema version isn't right for this.

    call = Tools.call(authority, pointer, opts)

    {calls, filters} =
      subschema
      |> Enum.with_index(&build_filter(&1, &2, call, authority, pointer, opts))
      |> Enum.unzip()

    parent = JsonPointer.backtrack!(pointer)

    additional_items =
      case Tools.subschema(caller, authority, parent) do
        %{"additionalItems" => _} ->
          additional_items_call =
            Tools.call(authority, JsonPointer.join(parent, "additionalItems"), opts)

          quote do
            unquote(additional_items_call)(item, path)
          end

        _ ->
          :ok
      end

    quote do
      require Exonerate.Context
      unquote(calls)
      defp unquote(call)({item, _index}, path), do: unquote(additional_items)
      unquote(filters)
    end
  end

  defp build_filter(_, index, call, authority, pointer, opts) do
    filter_pointer = JsonPointer.join(pointer, "#{index}")
    filter_call = Tools.call(authority, filter_pointer, opts)

    {quote do
       defp unquote(call)({item, unquote(index)}, path) do
         unquote(filter_call)(item, path)
       end
     end,
     quote do
       Exonerate.Context.filter(unquote(authority), unquote(filter_pointer), unquote(opts))
     end}
  end
end
