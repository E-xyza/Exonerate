defmodule Exonerate.Filter.UnevaluatedProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context
  defstruct [:context, :child, :evaluated_tokens]

  def parse(filter, %{"unevaluatedProperties" => false}) do
    %{filter | filters: [filter_from(filter, false) | filter.filters]}
  end

  def parse(filter = %{context: context}, %{"unevaluatedProperties" => _}) do
    child =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "unevaluatedProperties"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{filter | filters: [filter_from(filter, child) | filter.filters]}
  end

  defp filter_from(filter = %{context: context}, child) do
    %__MODULE__{
      context: context,
      child: child,
      evaluated_tokens: filter.evaluated_tokens ++ context.evaluated_tokens
    }
  end

  def compile(%__MODULE__{child: child}) do
    {[], List.wrap(if child, do: Context.compile(child))}
  end
end
