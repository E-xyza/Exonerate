defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  defmacro filter(name, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
