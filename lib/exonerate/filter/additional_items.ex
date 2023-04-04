defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(resource, parent_pointer)
    |> build_filter(resource, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, parent_pointer, opts) do
    entrypoint_pointer = JsonPointer.join(parent_pointer, "additionalItems")
    entrypoint_call = Tools.call(resource, entrypoint_pointer, :entrypoint, opts)
    context_pointer = JsonPointer.join(parent_pointer, "additionalItems")

    context_opts = Tools.scrub(opts)
    context_call = Tools.call(resource, context_pointer, context_opts)

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
end
