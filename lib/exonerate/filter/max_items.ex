defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context
  defstruct [:context, :count]

  def parse(filter, %{"maxItems" => count}) do
    %{
      filter
      | needs_accumulator: true,
        needs_array_in_accumulator: true,
        accumulator_pipeline: ["maxItems" | filter.accumulator_pipeline],
        accumulator_init: Map.put(filter.accumulator_init, :index, 0),
        filters: [%__MODULE__{context: filter.context, count: count} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[],
     [
       quote do
         defp unquote("maxItems")(acc, {path, _}) do
           if acc.index >= unquote(count) do
             Exonerate.mismatch(acc.array, path)
           end

           acc
         end
       end
     ]}
  end
end
