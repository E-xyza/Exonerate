defmodule Exonerate.Combining.Then do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
      end,
      opts
    )
  end
end
