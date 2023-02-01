defmodule Exonerate.Filter.AdditionalProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :child, :unevaluated_token]

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

  defp filter_from(artifact, child) do
    %__MODULE__{
      context: artifact.context,
      child: child,
      unevaluated_token: artifact.unevaluated_token
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

           Exonerate.Filter.UnevaluatedHelper.register_key(
             unquote(filter.unevaluated_token),
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

           Exonerate.Filter.UnevaluatedHelper.register_key(
             unquote(filter.unevaluated_token),
             k
           )

           seen
         end
       end,
       Validator.compile(child)
     ]}
  end
end
