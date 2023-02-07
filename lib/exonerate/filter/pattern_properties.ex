defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :patterns, :evaluated_tokens]

  def parse(filter = %{context: context}, %{"patternProperties" => patterns}) do
    patterns =
      Map.new(patterns, fn
        {pattern, _} ->
          {pattern,
           Context.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["patternProperties", pattern]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
      end)

    %{
      filter
      | iterate: true,
        kv_pipeline:
          Enum.map(patterns, fn {k, _} -> fun(filter, ["patternProperties", k]) end) ++
            filter.kv_pipeline,
        filters: [filter_from(filter, patterns) | filter.filters]
    }
  end

  defp filter_from(filter = %{context: context}, patterns) do
    %__MODULE__{
      context: filter.context,
      patterns: patterns,
      evaluated_tokens: filter.evaluated_tokens ++ context.evaluated_tokens
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

               Exonerate.Filter.UnevaluatedHelper.register_tokens(
                 unquote(filter.evaluated_tokens),
                 key
               )

               true
             else
               seen
             end
           end

           unquote(Context.compile(compiled))
         end
     end)}
  end
end
