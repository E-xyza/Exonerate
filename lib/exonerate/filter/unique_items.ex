defmodule Exonerate.Filter.UniqueItems do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context]

  def parse(artifact = %{context: context}, %{"uniqueItems" => true}) do
    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [{fun(artifact), []} | artifact.accumulator_pipeline],
      accumulator_init: Map.merge(artifact.accumulator_init, %{unique_set: MapSet.new(), index: 0}),
      filters: [%__MODULE__{context: context} | artifact.filters]}
  end
  def parse(artifact, _), do: artifact

  def compile(filter = %__MODULE__{}) do
    {[], [
      quote do
        defp unquote(fun(filter))(acc, {path, item}) do
          if item in acc.unique_set do
            Exonerate.mismatch(item, Path.join(path, to_string(acc.index)))
          end
          %{acc | unique_set: MapSet.put(acc.unique_set, item)}
        end
      end
    ]}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("uniqueItems")
    |> Validator.to_fun
  end
end
