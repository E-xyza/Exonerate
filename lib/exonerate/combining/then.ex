defmodule Exonerate.Combining.Then do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end,
      __CALLER__,
      opts
    )
  end
end
