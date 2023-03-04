defmodule Exonerate.Filter.MultipleOf do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: reenable the decision to force use with floats.

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(divisor, authority, pointer, opts) do
    quote do
      defp unquote(Tools.call(authority, pointer, opts))(integer, path) do
        case integer do
          value when rem(value, unquote(divisor)) === 0 ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(integer, unquote(pointer), path)
        end
      end
    end
  end
end
