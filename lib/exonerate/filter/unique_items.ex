defmodule Exonerate.Filter.UniqueItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context]

  def parse(filter = %{context: context}, %{"uniqueItems" => true}) do
    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: [fun(filter, "uniqueItems") | filter.accumulator_pipeline],
        accumulator_init:
          Map.merge(filter.accumulator_init, %{unique_set: MapSet.new(), index: 0}),
        filters: [%__MODULE__{context: context} | filter.filters]
    }
  end

  def parse(filter, _), do: filter

  def compile(filter = %__MODULE__{}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "uniqueItems"))(acc, {path, item}) do
           if item in acc.unique_set do
             Exonerate.mismatch(item, Path.join(path, to_string(acc.index)))
           end

           %{acc | unique_set: MapSet.put(acc.unique_set, item)}
         end
       end
     ]}
  end
end
