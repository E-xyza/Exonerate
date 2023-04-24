defmodule Exonerate.Filter.MultipleOf do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: reenable the decision to force use with floats.

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(divisor, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(integer, path) do
        case integer do
          number when rem(number, unquote(divisor)) === 0 ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(integer, unquote(resource), unquote(pointer), path)
        end
      end
    end
  end
end
