defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(limit, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(array, index, path) when index >= unquote(limit) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(pointer), path)
      end

      defp unquote(call)(_, _, _), do: :ok
    end
  end
end
