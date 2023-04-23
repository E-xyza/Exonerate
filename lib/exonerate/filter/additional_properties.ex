defmodule Exonerate.Filter.AdditionalProperties do
  @moduledoc false

  alias Exonerate.Context

  defmacro filter(name, pointer, opts) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(Context.scrub_opts(opts)))
    end
  end
end
