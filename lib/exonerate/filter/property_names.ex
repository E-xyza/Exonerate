defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Context

  defstruct [:context, :schema]

  def parse(filter, %{"propertyNames" => true}) do
    # true means no further conditions are added to the schema.
    # this header clause is provided as an optimization.
    filter
  end

  def parse(filter = %{context: context}, %{"propertyNames" => false}) do
    # false means only the empty object is valid
    # this is provided as an optimization.
    %{filter | iterate: false, filters: [%__MODULE__{context: context, schema: false}]}
  end

  def parse(filter = %{context: context}, %{"propertyNames" => schema}) do
    schema =
      Exonerate.Type.String.parse(
        Context.jump_into(filter.context, "propertyNames", true),
        schema
      )

    %{
      filter
      | iterate: true,
        filters: [%__MODULE__{context: context, schema: schema} | filter.filters],
        kv_pipeline: ["propertyNames" | filter.kv_pipeline]
    }
  end

  def compile(filter = %__MODULE__{schema: false}) do
    {[
       quote do
         defp unquote([])(object, path) when object != %{} do
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
           defp unquote("propertyNames")(seen, {path, key, value}) do
             unquote("propertyNames")(key, Path.join(path, key))
             seen
           end
         end
       ]}
  end
end
