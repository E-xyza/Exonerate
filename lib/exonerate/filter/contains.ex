defmodule Exonerate.Filter.Contains do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :contains, :min_contains]

  def parse(filter, %{"contains" => _, "minContains" => 0}), do: filter

  def parse(filter = %{context: context}, %{"contains" => _}) do
    schema =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "contains"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    filter = %__MODULE__{
      context: filter.context,
      contains: schema,
      min_contains: is_map_key(schema, "minContains")
    }

    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: [
          ["contains", ":reduce"] | filter.accumulator_pipeline
        ],
        post_reduce_pipeline: ["contains" | filter.post_reduce_pipeline],
        accumulator_init: Map.put_new(filter.accumulator_init, :contains, 0),
        filters: [filter | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{contains: contains}) do
    rest =
      if filter.min_contains do
        quote do
        end
      else
        quote do
          defp unquote("contains")(%{contains: 0}, {path, array}) do
            Exonerate.mismatch(array, path)
          end

          defp unquote("contains")(acc, {_path, _array}), do: acc
        end
      end

    {[],
     [
       quote do
         defp unquote(["contains", ":reduce"])(acc, {path, item}) do
           try do
             unquote("contains")(item, path)
             # yes, it has been seen
             %{acc | contains: acc.contains + 1}
           catch
             # don't update the "contains" value
             {:error, list} when is_list(list) ->
               acc
           end
         end

         unquote(rest)
         unquote(Context.compile(contains))
       end
     ]}
  end
end
