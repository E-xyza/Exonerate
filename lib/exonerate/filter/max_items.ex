defmodule Exonerate.Filter.MaxItems do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :count]

  def parse(artifact, %{"maxItems" => count}) do
    fun = fun0(artifact, "maxItems")

    %{artifact |
      needs_accumulator: true,
      needs_array_in_accumulator: true,
      accumulator_pipeline: [{fun, []} | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[], [
      quote do
        defp unquote(fun0(filter, "maxItems"))(acc, {path, _}) do
          if acc.index >= unquote(count) do
            Exonerate.mismatch(acc.array, path)
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
