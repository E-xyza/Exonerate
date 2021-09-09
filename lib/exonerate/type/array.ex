defmodule Exonerate.Type.Array do
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
    :additional_items,
    filters: [],
    pipeline: [],
    needs_array_in_accumulator: false,
    needs_accumulator: false,
    accumulator_init: %{},
    accumulator_pipeline: [],
    post_reduce_pipeline: []]

  @type t :: %__MODULE__{}

  # maxContains MUST precede contains so it is put onto the pipeline AFTER the contains
  # reduction element.
  # items MUST be last to detect the presence of prefixItems and also clear all filters
  # in the items = false optimization.
  @validator_filters ~w(minItems maxItems additionalItems prefixItems maxContains minContains contains uniqueItems items)
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
    {accumulator_pipeline, index_accumulator} = if :index in Map.keys(artifact.accumulator_init) do
      {
        artifact.accumulator_pipeline ++ [fun(artifact, ":index")],
        quote do
          defp unquote(fun(artifact, ":index"))(acc, _) do
            %{acc | index: acc.index + 1}
          end
        end
      }
    else
      {artifact.accumulator_pipeline, :ok}
    end

    accumulator = if artifact.needs_array_in_accumulator do
      quote do
        Map.put(unquote(Macro.escape(artifact.accumulator_init)), :array, array)
      end
    else
      Macro.escape(artifact.accumulator_init)
    end

    combining = Validator.combining(artifact.context, quote do array end, quote do path end)

    quote do
      defp unquote(fun(artifact, []))(array, path) when is_list(array) do
        array
        |> Enum.reduce(unquote(accumulator), fn item, acc ->
          Exonerate.pipeline(acc, {path, item}, unquote(accumulator_pipeline))
        end)
        |> Exonerate.pipeline({path, array}, unquote(artifact.post_reduce_pipeline))
        unquote_splicing(combining)
      end
      unquote(index_accumulator)
    end
  end
end
