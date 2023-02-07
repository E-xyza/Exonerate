defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :schema, :additional_items]

  def parse(filter = %{context: context}, %{"prefixItems" => s}) when is_list(s) do
    schemas =
      Enum.map(
        0..(length(s) - 1),
        &Context.parse(
          context.schema,
          JsonPointer.traverse(context.pointer, ["prefixItems", "#{&1}"]),
          authority: context.authority,
          format: context.format,
          draft: context.draft
        )
      )

    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: ["prefixItems" | filter.accumulator_pipeline],
        accumulator_init: Map.put(filter.accumulator_init, :index, 0),
        filters: [
          %__MODULE__{
            context: filter.context,
            schema: schemas,
            additional_items: filter.additional_items
          }
          | filter.filters
        ]
    }
  end

  def compile(filter = %__MODULE__{schema: schemas}) when is_list(schemas) do
    {trampolines, children} =
      schemas
      |> Enum.with_index()
      |> Enum.map(fn {schema, index} ->
        {quote do
           defp unquote("prefixItems")(acc = %{index: unquote(index)}, {path, item}) do
             unquote(["prefixItems", to_string(index)])(
               item,
               Path.join(path, unquote("#{index}"))
             )

             acc
           end
         end, Context.compile(schema)}
      end)
      |> Enum.unzip()

    additional_item_filter =
      if filter.additional_items do
        quote do
          defp unquote("prefixItems")(acc = %{index: index}, {path, item}) do
            unquote("additionalItems")(item, Path.join(path, to_string(index)))
            acc
          end
        end
      else
        quote do
          defp unquote("prefixItems")(acc = %{index: _}, {_item, _path}), do: acc
        end
      end

    {[], trampolines ++ [additional_item_filter] ++ children}
  end
end
