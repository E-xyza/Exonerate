defmodule Exonerate.Type.Object do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [
    :context,
    iterate: false,
    filters: [],
    kv_pipeline: [],
    pipeline: []
  ]

  @type t :: %__MODULE__{}

  # additionalProperties MUST precede patternProperties
  @validator_filters ~w(required maxProperties minProperties additionalProperties
    properties patternProperties dependentRequired dependentSchemas
    dependencies propertyNames)

  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  def parse(validator = %Validator{}, schema) do
    %__MODULE__{context: validator}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)
      artifact, _ -> artifact
    end)
  end

  @spec compile(t) :: Macro.t
  def compile(artifact) do
    iteration = List.wrap(if artifact.iterate do
      [quote do
        Enum.each(object, fn
          {k, v} ->
            Exonerate.pipeline(false, {path, k, v}, unquote(artifact.kv_pipeline))
        end)
      end]
    end)

    combining = Validator.combining(artifact.context, quote do object end, quote do path end)

    quote do
      defp unquote(fun(artifact, []))(object, path) when is_map(object) do
        Exonerate.pipeline(object, path, unquote(artifact.pipeline))
        unquote_splicing(iteration ++ combining)
      end
    end
  end
end
