defmodule Exonerate.Filter.MinItems do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :count]

  def parse(artifact, %{"minItems" => count}) do
    check_key = fun0(artifact, "minItems")

    %{artifact |
      needs_accumulator: true,
      post_reduce_pipeline: [{check_key, []} | artifact.post_reduce_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[], [
      quote do
        defp unquote(fun0(filter, "minItems"))(acc, {path, array}) do
          if acc.index < unquote(count) do
            Exonerate.mismatch(array, path)
          end
          acc
        end
      end
    ]}
  end

  defp fun0(filter_or_artifact = %_{}, what) do
    filter_or_artifact.context
    |> Validator.jump_into(what)
    |> Validator.to_fun
  end
end
