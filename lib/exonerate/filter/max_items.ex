defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context
  defstruct [:context, :count]

  import Context, only: [fun: 2]

  def parse(filter, %{"maxItems" => count}) do
    %{
      filter
      | needs_accumulator: true,
        needs_array_in_accumulator: true,
        accumulator_pipeline: [fun(filter, "maxItems") | filter.accumulator_pipeline],
        accumulator_init: Map.put(filter.accumulator_init, :index, 0),
        filters: [%__MODULE__{context: filter.context, count: count} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "maxItems"))(acc, {path, _}) do
           if acc.index >= unquote(count) do
             Exonerate.mismatch(acc.array, path)
           end

           acc
         end
       end
     ]}
  end
end
