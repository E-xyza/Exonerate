defmodule Exonerate.Filter.AdditionalProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :child]

  def parse(artifact = %{context: context}, %{"additionalProperties" => false}) do
    %{artifact |
      filters: [%__MODULE__{context: context, child: false} | artifact.filters],
      kv_pipeline: [fun(artifact) | artifact.kv_pipeline],
      iterate: true}
  end
  def parse(artifact = %{context: context}, %{"additionalProperties" => _}) do
    child = Validator.parse(
      context.schema,
      ["additionalProperties" | context.pointer],
      authority: context.authority)

    %{artifact |
      filters: [%__MODULE__{context: context, child: child} | artifact.filters],
      kv_pipeline: [fun(artifact) | artifact.kv_pipeline],
      iterate: true}
  end

  def compile(filter = %__MODULE__{child: false}) do
    {[], [quote do
      defp unquote(fun(filter))(seen, {path, k, v}) do
        unless seen do
          Exonerate.mismatch({k, v}, path)
        end
        seen
      end
    end]}
  end
  def compile(filter = %__MODULE__{child: child}) do
    {[], [quote do
      defp unquote(fun(filter))(seen, {path, k, v}) do
        unless seen do
          unquote(fun(filter))(v, Path.join(path, k))
        end
        seen
      end
    end, Validator.compile(child)]}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("additionalProperties")
    |> Validator.to_fun
  end
end
