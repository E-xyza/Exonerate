defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    special_opts = Keyword.merge(opts, type: "string")

    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(special_opts))
      end,
      opts
    )
  end
end
