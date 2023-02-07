defmodule Exonerate.Filter.MaxContains do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :maximum]

  def parse(filter = %{context: context}, %{"contains" => _, "maxContains" => maximum}) do
    %{
      filter
      | needs_accumulator: true,
        accumulator_pipeline: [fun(filter, "maxContains") | filter.accumulator_pipeline],
        accumulator_init: Map.put_new(filter.accumulator_init, :contains, 0),
        filters: [%__MODULE__{context: context, maximum: maximum} | filter.filters]
    }
  end

  # ignore when there is no "contains"
  def parse(filter, %{"maxContains" => _}), do: filter

  def compile(filter = %__MODULE__{maximum: maximum}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "maxContains"))(%{contains: contains}, {path, array})
              when contains > unquote(maximum) do
           Exonerate.mismatch(array, path)
         end

         defp unquote(fun(filter, "maxContains"))(acc, {_path, _array}), do: acc
       end
     ]}
  end
end
