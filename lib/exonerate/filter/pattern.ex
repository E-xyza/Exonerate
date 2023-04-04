defmodule Exonerate.Filter.Pattern do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(pattern, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(string, path) do
        if Regex.match?(sigil_r(<<unquote(pattern)>>, []), string) do
          :ok
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(string, unquote(resource), unquote(pointer), path)
        end
      end
    end
  end
end
