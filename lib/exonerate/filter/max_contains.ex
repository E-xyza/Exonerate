defmodule Exonerate.Filter.MaxContains do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(maximum, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(contains_count, parent, path) when contains_count > unquote(maximum) do
        require Exonerate.Tools
        Tools.mismatch(parent, unquote(pointer), path)
      end

      defp unquote(call)(_, _, _), do: :ok
    end
  end
end
