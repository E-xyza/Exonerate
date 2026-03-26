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
    call = Tools.call(resource, pointer, opts)

    if Code.ensure_loaded?(Exonerate.Decimal) and Exonerate.Decimal.enabled?(resource, pointer, opts) do
      build_decimal_filter(divisor, resource, pointer, call)
    else
      build_standard_filter(divisor, resource, pointer, call)
    end
  end

  defp build_standard_filter(divisor, resource, pointer, call) do
    quote do
      defp unquote(call)(integer, path) do
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

  defp build_decimal_filter(divisor, resource, pointer, call) do
    divisor_decimal = Exonerate.Decimal.from_schema(divisor)
    zero = Exonerate.Decimal.zero()

    quote do
      defp unquote(call)(value, path) do
        case Exonerate.Decimal.convert(value) do
          {:ok, decimal} ->
            remainder = Exonerate.Decimal.rem(decimal, unquote(Macro.escape(divisor_decimal)))

            case Exonerate.Decimal.compare(remainder, unquote(Macro.escape(zero))) do
              :eq ->
                :ok

              _ ->
                require Exonerate.Tools
                Exonerate.Tools.mismatch(value, unquote(resource), unquote(pointer), path)
            end

          {:error, reason} ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(value, unquote(resource), unquote(pointer), path, reason: reason)
        end
      end
    end
  end
end
