defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    resource
    |> build_filter(pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(resource, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(Tools.scrub(opts)))
    end
  end
end
