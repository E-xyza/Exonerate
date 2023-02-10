defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    code =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)
      |> Enum.map(fn
        {pattern, _} ->
          pointer = JsonPointer.traverse(pointer, pattern)

          quote do
            require Exonerate.Context
            Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
          end
      end)

    Tools.maybe_dump(code, opts)
  end
end
