defmodule Exonerate.Filter.MaxContains do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :maximum]

  def parse(artifact = %{context: context}, %{"contains" => _, "maxContains" => maximum}) do
    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [{fun(artifact), []} | artifact.accumulator_pipeline],
      accumulator_init: Map.put_new(artifact.accumulator_init, :contains, 0),
      filters: [%__MODULE__{context: context, maximum: maximum} | artifact.filters]}
  end
  def parse(artifact, %{"maxContains" => _}), do: artifact # ignore when there is no "contains"

  def compile(filter = %__MODULE__{maximum: maximum}) do
    {[], [
      quote do
        defp unquote(fun(filter))(%{contains: contains}, {path, array}) when contains > unquote(maximum) do
          Exonerate.mismatch(array, path)
        end
        defp unquote(fun(filter))(acc, {_path, _array}), do: acc
      end
    ]}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("maxContains")
    |> Validator.to_fun
  end
end
