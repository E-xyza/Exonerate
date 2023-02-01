defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :child, :unevaluated_token]

  import Validator, only: [fun: 2]

  def parse(artifact, %{"unevaluatedProperties" => false}) do
    %{
      artifact
      | filters: [filter_from(artifact, false) | artifact.filters],
        kv_pipeline: [fun(artifact, "unevaluatedProperties") | artifact.kv_pipeline],
        iterate: true
    }
  end

  def parse(artifact = %{context: context}, %{"unevaluatedProperties" => _}) do
    child =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "unevaluatedProperties"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      artifact
      | filters: [filter_from(artifact, child) | artifact.filters],
        kv_pipeline: [fun(artifact, "unevaluatedProperties") | artifact.kv_pipeline],
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
         defp unquote(fun(filter, "unevaluatedProperties"))(seen, {path, k, v}) do
           unless seen do
             Exonerate.mismatch({k, v}, path)
           end

           seen
         end
       end
     ]}
  end

  def compile(filter = %__MODULE__{child: child, unevaluated_token: unevaluated_token}) do
    {[],
     [
       quote do
         defp unquote(fun(filter, "unevaluatedProperties"))(_seen, {path, k, v}) do
           unless k in Process.get(unquote(unevaluated_token)) do
             unquote(fun(filter, "unevaluatedProperties"))(v, Path.join(path, k))
           end

           true
         end
       end,
       Validator.compile(child)
     ]}
  end
end
