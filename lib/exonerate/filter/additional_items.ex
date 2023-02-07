defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Context
  defstruct [:context, :additional_items]

  def parse(filter = %{context: context}, %{"additionalItems" => _}) do
    schema =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "additionalItems"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      filter
      | needs_accumulator: true,
        additional_items: true,
        filters: [%__MODULE__{context: context, additional_items: schema} | filter.filters]
    }
  end

  def compile(%__MODULE__{additional_items: schema}) do
    {[], [Context.compile(schema)]}
  end
end
