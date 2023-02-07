defmodule Exonerate.Filter.MinContains do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :minimum]

  def parse(filter = %{context: context}, %{"contains" => _, "minContains" => minimum})
      when minimum > 0 do
    %{
      filter
      | needs_accumulator: true,
        post_reduce_pipeline: [fun(filter, "minContains") | filter.post_reduce_pipeline],
        accumulator_init: Map.put_new(filter.accumulator_init, :contains, 0),
        filters: [%__MODULE__{context: context, minimum: minimum} | filter.filters]
    }
  end

  # ignore when there is no "contains"
  def parse(filter, %{"minContains" => _}), do: filter

  def compile(filter = %__MODULE__{minimum: minimum}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "minContains"))(%{contains: contains}, {path, array})
              when contains < unquote(minimum) do
           Exonerate.mismatch(array, path)
         end

         defp unquote(fun(filter, "minContains"))(acc, {_path, _array}), do: acc
       end
     ]}
  end
end
