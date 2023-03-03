defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    special_opts = Keyword.merge(opts, type: "string")

    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(special_opts))
      end,
      opts
    )
  end
end
