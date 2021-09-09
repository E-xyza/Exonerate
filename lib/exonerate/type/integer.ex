defmodule Exonerate.Type.Integer do
  @moduledoc false

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

  @validator_filters ~w(multipleOf minimum maximum exclusiveMinimum exclusiveMaximum)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Validator.t, Type.json) :: t
  # draft <= 7 refs inhibit type-based analysis
  def parse(validator = %{draft: draft}, %{"$ref" => _}) when draft in ~w(6 7) do
    %__MODULE__{context: validator}
  end
  
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
    combining = Validator.combining(artifact.context, quote do integer end, quote do path end)
    quote do
      defp unquote(fun(artifact, []))(integer, path) when is_integer(integer) do
        unquote_splicing(combining)
      end
    end
  end
end
