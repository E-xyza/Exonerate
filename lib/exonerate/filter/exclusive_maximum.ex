defmodule Exonerate.Filter.ExclusiveMaximum do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(__CALLER__, authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(true, caller, authority, pointer, opts) do
    # TODO: include a draft-4 warning
    call = Tools.call(authority, pointer, opts)

    maximum =
      caller
      |> Tools.parent(authority, pointer)
      |> Map.fetch!("maximum")

    quote do
      defp unquote(call)(number = unquote(maximum), path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(number, unquote(pointer), path)
      end

      defp unquote(call)(_, _), do: :ok
    end
  end

  defp build_filter(maximum, _caller, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(number, path) do
        case number do
          value when value < unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(pointer), path)
        end
      end
    end
  end
end
