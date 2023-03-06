defmodule Exonerate.Filter.UniqueItems do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(true, authority, pointer, opts) do
    quote do
      defp unquote(Tools.call(authority, pointer, opts))(item, so_far, path) do
        if item in so_far do
          require Exonerate.Tools
          Exonerate.Tools.mismatch(item, unquote(pointer), path)
        else
          :ok
        end
      end
    end
  end
end
