defmodule Exonerate.Filter.PatternProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :patterns]

  def parse(artifact = %{context: context}, %{"patternProperties" => patterns})  do
    patterns = Map.new(patterns, fn
      {pattern, _} ->
        {pattern,
          Validator.parse(
            context.schema,
            [pattern, "patternProperties" | context.pointer],
            authority: context.authority)}
    end)

    %{artifact |
      needs_accumulator: true,
      pattern_pipeline: Enum.map(patterns, fn {k, _} -> {fun(artifact, k), []} end),
      filters: [%__MODULE__{context: context, patterns: patterns} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{patterns: patterns}) do
    {[], Enum.map(patterns, fn
      {pattern, compiled} ->
        quote do
          defp unquote(fun(filter, pattern))(seen, {path, key, value}) do
            if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
              unquote(fun(filter,pattern))(value, Path.join(path, key))
            else
              seen
            end
          end
          unquote(Validator.compile(compiled))
        end
    end)}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("patternProperties")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("patternProperties")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
