defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
      end,
      opts
    )
  end
end
