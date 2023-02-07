defmodule Exonerate.Filter.Items do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :schema, :additional_items, :prefix_size]

  def parse(filter = %{context: context}, %{"items" => true}) do
    # true means any array is valid
    # this header clause is provided as an optimization.
    %{filter | filters: [%__MODULE__{context: context, schema: true} | filter.filters]}
  end

  def parse(filter = %{context: context}, schema = %{"items" => false}) do
    # false means everything after prefixItems gets checked.
    if prefix_items = schema["prefixItems"] do
      filter = %__MODULE__{context: context, schema: false, prefix_size: length(prefix_items)}

      %{
        filter
        | needs_accumulator: true,
          accumulator_pipeline: ["items" | filter.accumulator_pipeline],
          accumulator_init: Map.put(filter.accumulator_init, :index, 0),
          filters: [filter | filter.filters]
      }
    else
      # this is provided as an optimization.
      filter = %__MODULE__{context: context, schema: false, prefix_size: 0}
      %{filter | filters: [filter]}
    end
  end

  def parse(filter = %{context: context}, %{"items" => s}) when is_map(s) do
    fun = "items"

    schema =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "items"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: [fun | filter.accumulator_pipeline],
        accumulator_init: Map.put(filter.accumulator_init, :index, 0),
        filters: [
          %__MODULE__{
            context: context,
            schema: schema
          }
          | filter.filters
        ]
    }
  end

  def parse(filter = %{context: context}, %{"items" => s}) when is_list(s) do
    fun = "items"

    schemas =
      Enum.map(
        0..(length(s) - 1),
        &Context.parse(
          context.schema,
          JsonPointer.traverse(context.pointer, ["items", "#{&1}"]),
          authority: context.authority,
          format: context.format,
          draft: context.draft
        )
      )

    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: [fun | filter.accumulator_pipeline],
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

  def compile(%__MODULE__{schema: true}), do: {[], []}

  def compile(filter = %__MODULE__{schema: false, prefix_size: 0}) do
    {[
       quote do
         defp unquote([])(array, path) when is_list(array) and array != [] do
           Exonerate.mismatch(array, path, guard: "items")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{schema: false}) do
    {[],
     [
       quote do
         defp unquote("items")(acc = %{index: index}, {path, array})
              when index < unquote(filter.prefix_size) do
           acc
         end

         defp unquote("items")(%{index: index}, {path, array}) do
           Exonerate.mismatch(array, path, guard: to_string(index))
         end
       end
     ]}
  end

  def compile(filter = %__MODULE__{schema: schema}) when is_map(schema) do
    {[],
     [
       quote do
         defp unquote("items")(acc, {path, item}) do
           unquote("items")(item, Path.join(path, to_string(acc.index)))
           acc
         end

         unquote(Context.compile(schema))
       end
     ]}
  end

  def compile(filter = %__MODULE__{schema: schemas}) when is_list(schemas) do
    {trampolines, children} =
      schemas
      |> Enum.with_index()
      |> Enum.map(fn {schema, index} ->
        {quote do
           defp unquote("items")(acc = %{index: unquote(index)}, {path, item}) do
             unquote(["items", to_string(index)])(
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
          defp unquote("items")(acc = %{index: index}, {path, item}) do
            unquote("additionalItems")(item, Path.join(path, to_string(index)))
            acc
          end
        end
      else
        quote do
          defp unquote("items")(acc = %{index: _}, {_item, _path}), do: acc
        end
      end

    {[], trampolines ++ [additional_item_filter] ++ children}
  end
end
