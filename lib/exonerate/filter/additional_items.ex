defmodule Exonerate.Filter.AdditionalItems do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :additional_items]

  def parse(artifact = %{context: context}, %{"additionalItems" => schema}) do

    schema = Validator.parse(context.schema,
    ["additionalItems" | context.pointer],
    authority: context.authority)

    %{artifact |
      needs_enum: true,
      post_enum_pipeline: [{fun(artifact), []} | artifact.post_enum_pipeline],
      additional_items: true,
      filters: [%__MODULE__{context: context, additional_items: schema} | artifact.filters]}
  end

  def compile(%__MODULE__{additional_items: schema}) do
    {[], [Validator.compile(schema)]}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("additionalItems")
    |> Validator.to_fun
  end
end
