defmodule Exonerate.Filter.MaxLength do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    length =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(call)(string, path) do
          case String.length(string) do
            length when length <= unquote(length) ->
              :ok

            _ ->
              require Exonerate.Tools
              Exonerate.Tools.mismatch(string, unquote(schema_pointer), path)
          end
        end
      end,
      opts
    )
  end
end
