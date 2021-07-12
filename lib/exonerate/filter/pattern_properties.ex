defmodule Exonerate.Filter.PatternProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :children]

  def parse(artifact = %{context: context}, %{"patternProperties" => properties})  do
    children = properties
    |> Map.keys
    |> Enum.map(&Validator.parse(
      context.schema,
      [&1, "patternProperties" | context.pointer],
      authority: context.authority))

    patterns = properties
    |> Map.keys()
    |> Enum.map(&{fun(artifact, &1), &1})

    %{artifact |
      patterns: patterns,
      needs_accumulator: true,
      filters: [%__MODULE__{context: context, children: children} | artifact.filters]}
  end

  def compile(%__MODULE__{children: children}) do
    {[], Enum.map(children, &Validator.compile/1)}
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("patternProperties")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
