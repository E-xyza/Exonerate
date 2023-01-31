defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :schema]

  def parse(artifact, %{"propertyNames" => true}) do
    # true means no further conditions are added to the schema.
    # this header clause is provided as an optimization.
    artifact
  end

  def parse(artifact = %{context: context}, %{"propertyNames" => false}) do
    # false means only the empty object is valid
    # this is provided as an optimization.
    %{artifact | iterate: false, filters: [%__MODULE__{context: context, schema: false}]}
  end

  def parse(artifact = %Object{context: context}, %{"propertyNames" => schema}) do
    schema =
      Exonerate.Type.String.parse(
        Validator.jump_into(artifact.context, "propertyNames", true),
        schema
      )

    %{
      artifact
      | iterate: true,
        filters: [%__MODULE__{context: context, schema: schema} | artifact.filters],
        kv_pipeline: [fun(artifact, "propertyNames") | artifact.kv_pipeline]
    }
  end

  def compile(filter = %__MODULE__{schema: false}) do
    {[
       quote do
         defp unquote(fun(filter, []))(object, path) when object != %{} do
           Exonerate.mismatch(object, path, guard: "propertyNames")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{schema: schema}) do
    {guards, body} = Exonerate.Compiler.compile(schema, force: true)

    {[],
     guards ++
       body ++
       [
         quote do
           defp unquote(fun(filter, "propertyNames"))(seen, {path, key, value}) do
             unquote(fun(filter, "propertyNames"))(key, Path.join(path, key))
             seen
           end
         end
       ]}
  end
end
