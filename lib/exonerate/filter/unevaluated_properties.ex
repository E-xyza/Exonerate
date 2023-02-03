defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :child, :evaluated_tokens]

  import Validator, only: [fun: 2]

  def parse(artifact, %{"unevaluatedProperties" => false}) do
    %{artifact | filters: [filter_from(artifact, false) | artifact.filters]}
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

    %{artifact | filters: [filter_from(artifact, child) | artifact.filters]}
  end

  defp filter_from(artifact = %{context: context}, child) do
    %__MODULE__{
      context: context,
      child: child,
      evaluated_tokens: artifact.evaluated_tokens ++ context.evaluated_tokens
    }
  end

  def compile(%__MODULE__{child: child}) do
    {[], List.wrap(if child, do: Validator.compile(child))}
  end
end
