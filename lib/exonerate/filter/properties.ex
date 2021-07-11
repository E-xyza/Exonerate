defmodule Exonerate.Filter.Properties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :children]

  def parse(artifact = %{context: context}, %{"properties" => properties})  do
    children = properties
    |> Map.keys
    |> Enum.map(&Validator.parse(
      context.schema,
      [&1, "properties" | context.pointer],
      authority: context.authority))

    arrows = Map.new(properties, fn {property, _} -> {property, fun(artifact, property)} end)

    %{artifact |
      arrows: arrows,
      filters: [%__MODULE__{context: context, children: children} | artifact.filters]}
  end

  def compile(%__MODULE__{children: children}) do
    {[], Enum.map(children, &Validator.compile/1)}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("properties")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("properties")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
