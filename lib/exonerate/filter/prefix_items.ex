defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # TODO: unify opts scrubbing
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(resource, parent_pointer)
    |> build_filter(resource, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(parent = %{"prefixItems" => subschema}, resource, parent_pointer, opts) do
    pointer = JsonPointer.join(parent_pointer, "prefixItems")
    call = Tools.call(resource, pointer, opts)

    {calls, filters} =
      subschema
      |> Enum.with_index(&item_to_filter(&1, &2, resource, pointer, opts))
      |> Enum.unzip()

    additional_items = additional_items_for(parent, resource, parent_pointer, opts)

    quote do
      unquote(calls)
      defp unquote(call)({item, _index}, path), do: unquote(additional_items)
      unquote(filters)
    end
  end

  defp item_to_filter(_, index, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    context_pointer = JsonPointer.join(pointer, "#{index}")
    context_opts = Tools.scrub(opts)
    context_call = Tools.call(resource, context_pointer, context_opts)

    {
      quote do
        defp unquote(call)({item, unquote(index)}, path) do
          unquote(context_call)(item, path)
        end
      end,
      quote do
        require Exonerate.Context

        Exonerate.Context.filter(
          unquote(resource),
          unquote(context_pointer),
          unquote(context_opts)
        )
      end
    }
  end

  defp additional_items_for(parent, resource, parent_pointer, opts) do
    case parent do
      %{"items" => object} when is_map(object) ->
        additional_call = Tools.call(resource, JsonPointer.join(parent_pointer, "items"), opts)

        quote do
          unquote(additional_call)(item, path)
        end

      _ ->
        :ok
    end
  end
end
