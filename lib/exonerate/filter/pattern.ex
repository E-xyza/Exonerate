defmodule Exonerate.Filter.Pattern do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(pattern, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(string, path) do
        if Regex.match?(sigil_r(<<unquote(pattern)>>, []), string) do
          :ok
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end
end
