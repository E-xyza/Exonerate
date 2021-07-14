defmodule Exonerate.Filter.MaxContains do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :maximum]

  def parse(artifact = %{context: context}, %{"contains" => _, "maxContains" => maximum}) do
    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun(artifact, "maxContains") | artifact.accumulator_pipeline],
      accumulator_init: Map.put_new(artifact.accumulator_init, :contains, 0),
      filters: [%__MODULE__{context: context, maximum: maximum} | artifact.filters]}
  end
  def parse(artifact, %{"maxContains" => _}), do: artifact # ignore when there is no "contains"

  def compile(filter = %__MODULE__{maximum: maximum}) do
    {[], [
      quote do
        defp unquote(fun(filter, "maxContains"))(%{contains: contains}, {path, array}) when contains > unquote(maximum) do
          Exonerate.mismatch(array, path)
        end
        defp unquote(fun(filter, "maxContains"))(acc, {_path, _array}), do: acc
      end
    ]}
  end
end
