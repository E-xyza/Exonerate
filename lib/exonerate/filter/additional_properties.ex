defmodule Exonerate.Filter.AdditionalProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :child]

  def parse(artifact, %{"additionalProperties" => false}) do
    %{artifact | additional_properties: false}
  end
  def parse(artifact = %{context: context}, %{"additionalProperties" => _}) do
    child = Validator.parse(
      context.schema,
      ["additionalProperties" | context.pointer],
      authority: context.authority)

    %{artifact |
      filters: [%__MODULE__{context: context, child: child} | artifact.filters],
      additional_properties: fun(artifact)}
  end

  def compile(%__MODULE__{child: child}) do
    {[], [Validator.compile(child)]}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("additionalProperties")
    |> Validator.to_fun
  end
end
