defmodule Exonerate.Filter.Maximum do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(maximum, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    if Code.ensure_loaded?(Exonerate.Decimal) and Exonerate.Decimal.enabled?(resource, pointer, opts) do
      build_decimal_filter(maximum, resource, pointer, call)
    else
      build_standard_filter(maximum, resource, pointer, call)
    end
  end

  defp build_standard_filter(maximum, resource, pointer, call) do
    quote do
      defp unquote(call)(number, path) do
        case number do
          number when number <= unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(resource), unquote(pointer), path)
        end
      end
    end
  end

  defp build_decimal_filter(maximum, resource, pointer, call) do
    maximum_decimal = Exonerate.Decimal.from_schema(maximum)

    quote do
      defp unquote(call)(value, path) do
        case Exonerate.Decimal.convert(value) do
          {:ok, decimal} ->
            case Exonerate.Decimal.compare(decimal, unquote(Macro.escape(maximum_decimal))) do
              :gt ->
                require Exonerate.Tools
                Exonerate.Tools.mismatch(value, unquote(resource), unquote(pointer), path)

              _ ->
                :ok
            end

          {:error, reason} ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(value, unquote(resource), unquote(pointer), path, reason: reason)
        end
      end
    end
  end
end
