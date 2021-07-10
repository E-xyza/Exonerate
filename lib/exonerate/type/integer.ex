defmodule Exonerate.Type.Integer do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Compiler
  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  @validator_filters ~w(multipleOf minimum maximum exclusiveMinimum exclusiveMaximum)
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
    quote do
      defp unquote(Validator.to_fun(artifact.context))(integer, path) when is_integer(integer) do
        :ok
      end
    end
  end
end
