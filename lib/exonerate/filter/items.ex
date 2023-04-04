defmodule Exonerate.Filter.Items do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(resource, parent_pointer)
    |> build_filter(resource, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # legacy "items" which is now "prefixItems"
  defp build_filter(%{"items" => subschema}, resource, parent_pointer, opts)
       when is_list(subschema) do

    this_pointer = JsonPointer.join(parent_pointer, "items")

    call = Tools.call(resource, this_pointer, opts)

    {calls, filters} =
      subschema
      |> Enum.with_index(&build_filter(&1, &2, call, resource, this_pointer, opts))
      |> Enum.unzip()

    quote do
      require Exonerate.Context
      unquote(calls)
      defp unquote(call)({item, _index}, path), do: :ok
      unquote(filters)
    end
  end

  defp build_filter(context = %{"items" => subschema}, resource, parent_pointer, opts)
       when is_map(subschema) or is_boolean(subschema) do
    entrypoint_pointer = JsonPointer.join(parent_pointer, "items")
    entrypoint_call = Tools.call(resource, entrypoint_pointer, :entrypoint, opts)

    context_opts = Tools.scrub(opts)
    context_pointer = JsonPointer.join(parent_pointer, "items")
    context_call = Tools.call(resource, context_pointer, context_opts)

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

          Exonerate.Context.filter(
            unquote(resource),
            unquote(context_pointer),
            unquote(context_opts)
          )
        end

      _ ->
        quote do
          defp unquote(entrypoint_call)({item, _index}, path) do
            unquote(context_call)(item, path)
          end

          require Exonerate.Context

          Exonerate.Context.filter(
            unquote(resource),
            unquote(context_pointer),
            unquote(context_opts)
          )
        end
    end
  end

  defp build_filter(_, index, call, resource, pointer, opts) do
    context_pointer = JsonPointer.join(pointer, "#{index}")
    context_opts = Tools.scrub(opts)
    context_call = Tools.call(resource, context_pointer, context_opts)

    {quote do
       defp unquote(call)({item, unquote(index)}, path) do
         unquote(context_call)(item, path)
       end
     end,
     quote do
       Exonerate.Context.filter(
         unquote(resource),
         unquote(context_pointer),
         unquote(context_opts)
       )
     end}
  end
end
