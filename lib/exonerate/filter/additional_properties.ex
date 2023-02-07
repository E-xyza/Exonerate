defmodule Exonerate.Filter.AdditionalProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context
  defstruct [:context, :child, :evaluated_tokens]

  import Context, only: [fun: 2]

  def parse(filter = %{context: context}, %{"additionalProperties" => false}) do
    %{
      filter
      | filters: [filter_from(filter, false) | filter.filters],
        kv_pipeline: [fun(filter, "additionalProperties") | filter.kv_pipeline],
        iterate: true
    }
  end

  def parse(filter = %{context: context}, %{"additionalProperties" => _}) do
    child =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "additionalProperties"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      filter
      | filters: [filter_from(filter, child) | filter.filters],
        kv_pipeline: [fun(filter, "additionalProperties") | filter.kv_pipeline],
        iterate: true
    }
  end

  defp filter_from(filter = %{context: context}, child) do
    %__MODULE__{
      context: context,
      child: child,
      evaluated_tokens: filter.evaluated_tokens ++ context.evaluated_tokens
    }
  end

  def compile(filter = %__MODULE__{child: false}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "additionalProperties"))(seen, {path, k, v}) do
           unless seen do
             Exonerate.mismatch({k, v}, path)
           end

           require Exonerate.Filter.UnevaluatedHelper

           Exonerate.Filter.UnevaluatedHelper.register_tokens(
             unquote(filter.evaluated_tokens),
             k
           )

           seen
         end
       end
     ]}
  end

  def compile(filter = %__MODULE__{child: child}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "additionalProperties"))(seen, {path, k, v}) do
           unless seen do
             unquote(fun(filter, "additionalProperties"))(v, Path.join(path, k))
           end

           require Exonerate.Filter.UnevaluatedHelper

           Exonerate.Filter.UnevaluatedHelper.register_tokens(
             unquote(filter.evaluated_tokens),
             k
           )

           seen
         end
       end,
       Context.compile(child)
     ]}
  end
end
