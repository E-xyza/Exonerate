defmodule Exonerate.Filter.AdditionalProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :child, :evaluated_tokens]

  import Validator, only: [fun: 2]

  def parse(artifact = %{context: context}, %{"additionalProperties" => false}) do
    %{
      artifact
      | filters: [filter_from(artifact, false) | artifact.filters],
        kv_pipeline: [fun(artifact, "additionalProperties") | artifact.kv_pipeline],
        iterate: true
    }
  end

  def parse(artifact = %{context: context}, %{"additionalProperties" => _}) do
    child =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "additionalProperties"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      artifact
      | filters: [filter_from(artifact, child) | artifact.filters],
        kv_pipeline: [fun(artifact, "additionalProperties") | artifact.kv_pipeline],
        iterate: true
    }
  end

  defp filter_from(artifact = %{context: context}, child) do
    %__MODULE__{
      context: context,
      child: child,
      evaluated_tokens: artifact.evaluated_tokens ++ context.evaluated_tokens
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
       Validator.compile(child)
     ]}
  end
end
