defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(authority, parent_pointer)
    |> build_filter(authority, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, parent_pointer, opts) do
    entrypoint_pointer = JsonPointer.join(parent_pointer, ["additionalItems", ":entrypoint"])
    entrypoint_call = Tools.call(authority, entrypoint_pointer, opts)
    context_pointer = JsonPointer.join(parent_pointer, "additionalItems")
    context_call = Tools.call(authority, context_pointer, opts)

    case context do
      # TODO: add a compiler error if this isn't a list
      %{"items" => prefix} when is_list(prefix) ->
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
end
