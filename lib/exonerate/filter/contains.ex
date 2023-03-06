defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(authority, pointer, opts) do
    authority
    |> build_filter(pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(authority, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end
end
