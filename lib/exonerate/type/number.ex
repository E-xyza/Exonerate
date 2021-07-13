defmodule Exonerate.Type.Number do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  @validator_filters ~w(minimum maximum exclusiveMinimum exclusiveMaximum multipleOf)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Validator.t, Type.json) :: t
  def parse(validator, schema) do
    %__MODULE__{context: validator}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)
      artifact, _ -> artifact
    end)
  end

  @impl true
  @spec compile(t) :: Macro.t
  def compile(artifact) do
    combining = Validator.combining(artifact.context, quote do number end, quote do path end)

    quote do
      defp unquote(fun(artifact, []))(number, path) when is_number(number) do
        unquote_splicing(combining)
      end
    end
  end
end
