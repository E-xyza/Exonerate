defmodule Exonerate.Filter.PropertyNames do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Type.Object
  alias Exonerate.Validator
  defstruct [:context, :schema]

  def parse(artifact = %Object{context: context}, %{"propertyNames" => schema})  do
    schema = Exonerate.Type.String.parse(Validator.jump_into(artifact.context, "propertyNames", true), schema)

    %{artifact |
      needs_accumulator: true,
      fallback: {:name, fun(artifact)},
      filters: [%__MODULE__{context: context, schema: schema} | artifact.filters]}
  end

  def compile(%__MODULE__{schema: schema}) do
    Exonerate.Compiler.compile(schema, force: true)
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("propertyNames")
    |> Validator.to_fun
  end

end
