defmodule Exonerate.Type.Null do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools

  @filters Combining.filters()

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    filter_clauses =
      for filter <- @filters, is_map_key(context, filter) do
        filter_call =
          Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

        quote do
          :ok <- unquote(filter_call)(null, path)
        end
      end

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(null, path)
           when is_nil(null) do
        with unquote_splicing(filter_clauses) do
          :ok
        end
      end
    end
  end

  defmacro accessories(_, _, _), do: []
end
