defmodule Exonerate.Filter.PropertyNames do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :spec]

  def parse(artifact = %{context: context}, %{"propertyNames" => spec})  do
    spec = Exonerate.Type.String.parse(Validator.jump_into(artifact.context, "propertyNames", true), spec)

    %{artifact |
      needs_enum: true,
      fallback: {:name, fun(artifact)},
      filters: [%__MODULE__{context: context, spec: spec} | artifact.filters]}
  end

  def compile(%__MODULE__{spec: spec}) do
    {[], [
      Exonerate.Compiler.compile(spec)
    ]}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("propertyNames")
    |> Validator.to_fun
  end

end
