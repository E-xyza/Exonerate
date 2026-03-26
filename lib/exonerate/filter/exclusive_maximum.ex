defmodule Exonerate.Filter.ExclusiveMaximum do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(true, caller, resource, pointer, opts) do
    # TODO: include a draft-4 warning
    call = Tools.call(resource, pointer, opts)

    maximum =
      caller
      |> Tools.parent(resource, pointer)
      |> Map.fetch!("maximum")

    if Code.ensure_loaded?(Exonerate.Decimal) and Exonerate.Decimal.enabled?(resource, pointer, opts) do
      maximum_decimal = Exonerate.Decimal.from_schema(maximum)

      quote do
        defp unquote(call)(value, path) do
          case Exonerate.Decimal.convert(value) do
            {:ok, decimal} ->
              case Exonerate.Decimal.compare(decimal, unquote(Macro.escape(maximum_decimal))) do
                :eq ->
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
    else
      quote do
        defp unquote(call)(number = unquote(maximum), path) do
          require Exonerate.Tools
          Exonerate.Tools.mismatch(number, unquote(resource), unquote(pointer), path)
        end

        defp unquote(call)(_, _), do: :ok
      end
    end
  end

  defp build_filter(maximum, _caller, resource, pointer, opts) do
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
          number when number < unquote(maximum) ->
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
              :lt ->
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
