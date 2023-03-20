defmodule Exonerate.Type.Array.Tracked do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    if is_map_key(context, "unevaluatedItems") or is_map_key(context, "additionalItems") do
      trivial_filter(call, context, authority, pointer, Keyword.delete(opts, :tracked))
    else
      general_filter(call, context, authority, pointer, opts)
    end
  end

  defp trivial_filter(_, _, _, _, _) do
    quote do
    end
  end

  defp general_filter(_, _, _, _, _) do
    quote do
    end
  end
end
