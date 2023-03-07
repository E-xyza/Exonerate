defmodule Exonerate.Type.Boolean do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools

  @filters Combining.filters()

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, pointer, opts) do
    filter_clauses =
      for filter <- @filters, is_map_key(context, filter) do
        filter_call =
          Tools.call(authority, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

        quote do
          :ok <- unquote(filter_call)(boolean, path)
        end
      end

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(boolean, path)
           when is_boolean(boolean) do
        with unquote_splicing(filter_clauses) do
          :ok
        end
      end
    end
  end

  defmacro accessories(_, _, _), do: []
end
