defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Tools

  defmacro context(resource, pointer, opts) do
    resource
    |> build_context(pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(resource, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(Tools.scrub(opts)))
    end
  end
end
