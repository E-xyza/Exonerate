defmodule Exonerate.Filter.MinContains do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  
  import Validator, only: [fun: 2]

  defstruct [:context, :minimum]

  def parse(artifact = %{context: context}, %{"contains" => _, "minContains" => minimum}) when minimum > 0 do
    %{artifact |
      needs_accumulator: true,
      post_reduce_pipeline: [fun(artifact, "minContains") | artifact.post_reduce_pipeline],
      accumulator_init: Map.put_new(artifact.accumulator_init, :contains, 0),
      filters: [%__MODULE__{context: context, minimum: minimum} | artifact.filters]}
  end
  def parse(artifact, %{"minContains" => _}), do: artifact # ignore when there is no "contains"

  def compile(filter = %__MODULE__{minimum: minimum}) do
    {[], [
      quote do
        defp unquote(fun(filter, "minContains"))(%{contains: contains}, {path, array}) when contains < unquote(minimum) do
          Exonerate.mismatch(array, path)
        end
        defp unquote(fun(filter, "minContains"))(acc, {_path, _array}), do: acc
      end
    ]}
  end
end
