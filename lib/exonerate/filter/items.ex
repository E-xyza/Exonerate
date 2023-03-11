defmodule Exonerate.Filter.Items do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(authority, parent_pointer)
    |> build_filter(authority, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # legacy "items" which is now "prefixItems"
  defp build_filter(context = %{"items" => subschema}, authority, parent_pointer, opts)
       when is_list(subschema) do
    # TODO: warn if the schema version isn't right for this.
    this_pointer = JsonPointer.join(parent_pointer, "items")

    call = Tools.call(authority, this_pointer, opts)

    {calls, filters} =
      subschema
      |> Enum.with_index(&build_filter(&1, &2, call, authority, this_pointer, opts))
      |> Enum.unzip()

    quote do
      require Exonerate.Context
      unquote(calls)
      defp unquote(call)({item, _index}, path), do: :ok
      unquote(filters)
    end
  end

  defp build_filter(context = %{"items" => subschema}, authority, parent_pointer, opts)
       when is_map(subschema) or is_boolean(subschema) do
    entrypoint_pointer = JsonPointer.join(parent_pointer, ["items", ":entrypoint"])
    entrypoint_call = Tools.call(authority, entrypoint_pointer, opts)
    context_pointer = JsonPointer.join(parent_pointer, "items")
    context_call = Tools.call(authority, context_pointer, opts)

    case context do
      %{"prefixItems" => prefix} ->
        prefix_length = length(prefix)

        quote do
          defp unquote(entrypoint_call)({item, index}, path) when index < unquote(prefix_length),
            do: :ok

          defp unquote(entrypoint_call)({item, _index}, path) do
            unquote(context_call)(item, path)
          end

          require Exonerate.Context
          Exonerate.Context.filter(unquote(authority), unquote(context_pointer), unquote(opts))
        end

      _ ->
        quote do
          defp unquote(entrypoint_call)({item, _index}, path) do
            unquote(context_call)(item, path)
          end

          require Exonerate.Context
          Exonerate.Context.filter(unquote(authority), unquote(context_pointer), unquote(opts))
        end
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
