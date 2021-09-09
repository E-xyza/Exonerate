defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :patterns]

  def parse(artifact = %{context: context}, %{"patternProperties" => patterns})  do
    patterns = Map.new(patterns, fn
      {pattern, _} ->
        {pattern,
          Validator.parse(
            context.schema,
            [pattern, "patternProperties" | context.pointer],
            authority: context.authority,
            format: context.format,
            draft: context.draft)}
    end)

    filter = %__MODULE__{context: context, patterns: patterns}

    %{artifact |
      iterate: true,
      kv_pipeline: Enum.map(patterns, fn {k, _} -> fun(artifact, ["patternProperties", k]) end) ++ artifact.kv_pipeline,
      filters: [filter | artifact.filters]}
  end

  def compile(filter = %__MODULE__{patterns: patterns}) do
    {[], Enum.map(patterns, fn
      {pattern, compiled} ->
        quote do
          defp unquote(fun(filter, ["patternProperties", pattern]))(seen, {path, key, value}) do
            if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
              unquote(fun(filter, ["patternProperties", pattern]))(value, Path.join(path, key))
              true
            else
              seen
            end
          end
          unquote(Validator.compile(compiled))
        end
    end)}
  end
end
