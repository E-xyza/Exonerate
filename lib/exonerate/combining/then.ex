defmodule Exonerate.Combining.Then do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
      end,
      opts
    )
  end
end
