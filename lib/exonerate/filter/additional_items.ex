defmodule Exonerate.Filter.AdditionalItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :additional_items]

  def parse(artifact = %{context: context}, %{"additionalItems" => _}) do
    schema =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "additionalItems"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    %{
      artifact
      | needs_accumulator: true,
        additional_items: true,
        filters: [%__MODULE__{context: context, additional_items: schema} | artifact.filters]
    }
  end

  def compile(%__MODULE__{additional_items: schema}) do
    {[], [Validator.compile(schema)]}
  end
end
