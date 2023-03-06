defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(limit, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(array, index, path) when index >= unquote(limit) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(pointer), path)
      end

      defp unquote(call)(_, _, _), do: :ok
    end
  end
end
