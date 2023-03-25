defmodule Exonerate.Filter.Maximum do
  @moduledoc false

  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(maximum, _caller, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(number, path) do
        case number do
          value when value <= unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(pointer), path)
        end
      end
    end
  end
end
