defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  defmacro filter(name, pointer, opts) do
    context_opts = Tools.scrub(opts)
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(context_opts))
    end
  end
end
