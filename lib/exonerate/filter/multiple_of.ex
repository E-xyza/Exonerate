defmodule Exonerate.Filter.MultipleOf do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    divisor =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(call)(integer, path) do
          case integer do
            value when rem(value, unquote(divisor)) === 0 ->
              :ok

            _ ->
              require Exonerate.Tools
              Exonerate.Tools.mismatch(integer, unquote(schema_pointer), path)
          end
        end
      end,
      opts
    )
  end
end
