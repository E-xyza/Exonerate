defmodule Exonerate.Filter.Pattern do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    pattern =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(call)(string, path) do
          if Regex.match?(sigil_r(<<unquote(pattern)>>, []), string) do
            :ok
          else
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(schema_pointer), path)
          end
        end
      end,
      opts
    )
  end
end
