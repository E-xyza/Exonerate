defmodule Exonerate.Type.Number do
  @moduledoc false

  @behaviour Exonerate.Type

  # note this module ONLY implements "float".  If something has the "number" type declaration
  # it will implement both Number and Integer, this is handled at the Context level.

  alias Exonerate.Combining
  alias Exonerate.Tools

  @modules Combining.merge(%{
             "maximum" => Exonerate.Filter.Maximum,
             "minimum" => Exonerate.Filter.Minimum,
             "exclusiveMaximum" => Exonerate.Filter.ExclusiveMaximum,
             "exclusiveMinimum" => Exonerate.Filter.ExclusiveMinimum
           })

  @filters Map.keys(@modules)

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    # TODO: make sure that this actually detects the draft version before
    # attempting to adjust the draft

    filter_clauses =
      for filter <- @filters, is_map_key(context, filter) do
        filter_call =
          Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

        quote do
          :ok <- unquote(filter_call)(float, path)
        end
      end

    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(float, path) when is_float(float) do
        with unquote_splicing(filter_clauses) do
          :ok
        end
      end
    end
  end

  # there are no accessories for "number" because these will ALWAYS be included in "integer".
  defmacro accessories(_, _, _), do: []
end
