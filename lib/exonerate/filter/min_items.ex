defmodule Exonerate.Filter.MinItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :count]

  def parse(filter, %{"minItems" => count}) do
    check_key = fun(filter, "minItems")

    %{
      filter
      | needs_accumulator: true,
        post_reduce_pipeline: [check_key | filter.post_reduce_pipeline],
        accumulator_init: Map.put(filter.accumulator_init, :index, 0),
        filters: [%__MODULE__{context: filter.context, count: count} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "minItems"))(acc, {path, array}) do
           if acc.index < unquote(count) do
             Exonerate.mismatch(array, path)
           end

           acc
         end
       end
     ]}
  end
end
