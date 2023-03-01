defmodule Exonerate.Type.Number do
  @moduledoc false

  # note this module ONLY implements "float".  If something has the "number" type declaration
  # it will implement both Number and Integer, this is handled at the Context level.

  alias Exonerate.Combining
  alias Exonerate.Draft
  alias Exonerate.Tools

  @modules Combining.merge(%{
             "maximum" => Exonerate.Filter.Maximum,
             "minimum" => Exonerate.Filter.Minimum,
             "exclusiveMaximum" => Exonerate.Filter.ExclusiveMaximum,
             "exclusiveMinimum" => Exonerate.Filter.ExclusiveMinimum
           })

  @module_keys Map.keys(@modules)

  defp filters(opts) do
    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") do
      @module_keys -- ["$ref"]
    else
      @module_keys
    end
  end

  def filter(schema, name, pointer, opts) do
    filters =
      schema
      |> Map.take(filters(opts))
      |> Enum.map(&filter_for(&1, name, pointer))

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_float(content) do
        with unquote_splicing(filters) do
          :ok
        end
      end
    end
  end

  defp filter_for({filter, _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.join(Combining.adjust(filter))
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      :ok <- unquote(call)(content, path)
    end
  end

  # number doesn't require accessories because integer will always provide it
  # and anything with number must have integer.
  def accessories(_schema, _name, _pointer, _opts), do: []
end
