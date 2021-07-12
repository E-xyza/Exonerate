defmodule Exonerate.Type.Array do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

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

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  @validator_filters ~w(minItems maxItems additionalItems items contains uniqueItems)
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
    {accumulator_pipeline, index_accumulator} = if :index in Map.keys(artifact.accumulator_init) do
      index_fun = artifact.context
      |> Validator.jump_into(":index")
      |> Validator.to_fun()

      {
        artifact.accumulator_pipeline ++ [{index_fun, []}],
        quote do
          defp unquote(index_fun)(acc, _) do
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

    quote do
      defp unquote(Validator.to_fun(artifact.context))(array, path) when is_list(array) do
        array
        |> Enum.reduce(unquote(accumulator), fn item, acc ->
          Exonerate.pipeline(acc, {path, item}, unquote(accumulator_pipeline))
        end)
        |> Exonerate.pipeline({path, array}, unquote(artifact.post_reduce_pipeline))
        :ok
      end
      unquote(index_accumulator)
    end
  end
end
