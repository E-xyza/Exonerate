defmodule Exonerate.Filter.Minimum do
  @moduledoc false
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(minimum, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(number, path) do
        case number do
          number when number >= unquote(minimum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(resource), unquote(pointer), path)
        end
      end
    end
  end
end
