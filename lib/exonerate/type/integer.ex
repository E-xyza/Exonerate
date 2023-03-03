defmodule Exonerate.Type.Integer do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Draft
  alias Exonerate.Tools

  @modules Combining.merge(%{
             "maximum" => Exonerate.Filter.Maximum,
             "minimum" => Exonerate.Filter.Minimum,
             "exclusiveMaximum" => Exonerate.Filter.ExclusiveMaximum,
             "exclusiveMinimum" => Exonerate.Filter.ExclusiveMinimum,
             "multipleOf" => Exonerate.Filter.MultipleOf
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
    # TODO: make sure that this actually detects the draft version before
    # attempting to adjust the draft

    filters =
      schema
      |> Map.take(filters(opts))
      |> Enum.map(&filter_for(&1, name, pointer))

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_integer(content) do
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

  def accessories(schema, name, pointer, opts) do
    for filter_name <- filters(opts),
        is_map_key(schema, filter_name),
        not Combining.filter?(filter_name) do
      module = @modules[filter_name]
      pointer = JsonPointer.join(pointer, filter_name)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(name), unquote(pointer), unquote(opts))
      end
    end
  end
end
