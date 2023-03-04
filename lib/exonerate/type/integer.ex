defmodule Exonerate.Type.Integer do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools

  @modules Combining.merge(%{
             "maximum" => Exonerate.Filter.Maximum,
             "minimum" => Exonerate.Filter.Minimum,
             "exclusiveMaximum" => Exonerate.Filter.ExclusiveMaximum,
             "exclusiveMinimum" => Exonerate.Filter.ExclusiveMinimum,
             "multipleOf" => Exonerate.Filter.MultipleOf
           })

  @filters Map.keys(@modules)

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, pointer, opts) do
    # TODO: make sure that this actually detects the draft version before
    # attempting to adjust the draft

    filter_clauses =
      for filter <- @filters, is_map_key(context, filter) do
        filter_call = Tools.call(authority, JsonPointer.join(pointer, filter), opts)

        quote do
          :ok <- unquote(filter_call)(integer, path)
        end
      end

    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(integer, path) when is_integer(integer) do
        with unquote_splicing(filter_clauses) do
          :ok
        end
      end
    end
  end

  defmacro accessories(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_accessories(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, name, pointer, opts) do
    for filter <- @filters, is_map_key(context, filter), not Combining.filter?(filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(name), unquote(pointer), unquote(opts))
      end
    end
  end
end
