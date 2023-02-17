defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  defmacro filter_from_cached(name, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
