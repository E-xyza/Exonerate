defmodule Exonerate.Filter.UniqueItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(true, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(item, so_far, path) do
        if item in so_far do
          require Exonerate.Tools
          Exonerate.Tools.mismatch(item, unquote(resource), unquote(pointer), path)
        else
          :ok
        end
      end
    end
  end
end
