defmodule Exonerate.Filter.ExclusiveMinimum do
  @moduledoc false
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(true, caller, resource, pointer, opts) do
    # TODO: include a draft-4 warning
    call = Tools.call(resource, pointer, opts)

    minimum =
      caller
      |> Tools.parent(resource, pointer)
      |> Map.fetch!("minimum")

    quote do
      defp unquote(call)(number = unquote(minimum), path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(number, unquote(pointer), path)
      end

      defp unquote(call)(_, _), do: :ok
    end
  end

  defp build_filter(minimum, _caller, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(number, path) do
        case number do
          number when number > unquote(minimum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(pointer), path)
        end
      end
    end
  end
end
