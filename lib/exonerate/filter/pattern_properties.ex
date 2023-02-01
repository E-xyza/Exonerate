defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :patterns, :unevaluated_token]

  def parse(artifact = %{context: context}, %{"patternProperties" => patterns}) do
    patterns =
      Map.new(patterns, fn
        {pattern, _} ->
          {pattern,
           Validator.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["patternProperties", pattern]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
      end)

    %{
      artifact
      | iterate: true,
        kv_pipeline:
          Enum.map(patterns, fn {k, _} -> fun(artifact, ["patternProperties", k]) end) ++
            artifact.kv_pipeline,
        filters: [filter_from(artifact, patterns) | artifact.filters]
    }
  end

  defp filter_from(artifact, patterns) do
    %__MODULE__{
      context: artifact.context,
      patterns: patterns,
      unevaluated_token: artifact.unevaluated_token
    }
  end

  def compile(filter = %__MODULE__{patterns: patterns}) do
    {[],
     Enum.map(patterns, fn
       {pattern, compiled} ->
         quote do
           defp unquote(fun(filter, ["patternProperties", pattern]))(seen, {path, key, value}) do
             if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
               unquote(fun(filter, ["patternProperties", pattern]))(value, Path.join(path, key))

               require Exonerate.Filter.UnevaluatedHelper

               Exonerate.Filter.UnevaluatedHelper.register_key(
                 unquote(filter.unevaluated_token),
                 key
               )

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
