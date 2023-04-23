defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    context_opts = Context.scrub_opts(opts)

    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(context_opts))
    end
  end
end
