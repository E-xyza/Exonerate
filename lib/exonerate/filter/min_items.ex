defmodule Exonerate.Filter.MinItems do
  @moduledoc false
  
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :count]

  def parse(artifact, %{"minItems" => count}) do
    check_key = fun(artifact, "minItems")

    %{artifact |
      needs_accumulator: true,
      post_reduce_pipeline: [check_key | artifact.post_reduce_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[], [
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
