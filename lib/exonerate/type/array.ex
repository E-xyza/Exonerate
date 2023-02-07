defmodule Exonerate.Type.Array do
  @moduledoc false
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [
    :context,
    :additional_items,
    filters: [],
    pipeline: [],
    needs_array_in_accumulator: false,
    needs_accumulator: false,
    accumulator_init: %{},
    accumulator_pipeline: [],
    post_reduce_pipeline: []
  ]

  @type t :: %__MODULE__{}

  # maxContains MUST precede contains so it is put onto the pipeline AFTER the contains
  # reduction element.
  # items MUST be last to detect the presence of prefixItems and also clear all filters
  # in the items = false optimization.
  @context_filters ~w(minItems maxItems additionalItems prefixItems maxContains minContains contains uniqueItems items)
  @context_modules Map.new(@context_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Context.t(), Type.json()) :: t
  # draft <= 7 refs inhibit type-based analysis
  def parse(context = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: context}
  end

  def parse(context, schema) do
    %__MODULE__{context: context}
    |> Tools.collect(@context_filters, fn
      filter, filter when is_map_key(schema, filter) ->
        Filter.parse(filter, @context_modules[filter], schema)

      filter, _ ->
        filter
    end)
  end

  @impl true
  @spec compile(t) :: Macro.t()
  def compile(filter) do
    {accumulator_pipeline, index_accumulator} =
      if :index in Map.keys(filter.accumulator_init) do
        {
          filter.accumulator_pipeline ++ [fun(filter, ":index")],
          quote do
            defp unquote(fun(filter, ":index"))(acc, _) do
              %{acc | index: acc.index + 1}
            end
          end
        }
      else
        {filter.accumulator_pipeline, :ok}
      end

    accumulator =
      if filter.needs_array_in_accumulator do
        quote do
          Map.put(unquote(Macro.escape(filter.accumulator_init)), :array, array)
        end
      else
        Macro.escape(filter.accumulator_init)
      end

    combining =
      Context.combining(
        filter.context,
        quote do
          array
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote(fun(filter, []))(array, path) when is_list(array) do
        array
        |> Enum.reduce(unquote(accumulator), fn item, acc ->
          Exonerate.pipeline(acc, {path, item}, unquote(accumulator_pipeline))
        end)
        |> Exonerate.pipeline({path, array}, unquote(filter.post_reduce_pipeline))

        unquote_splicing(combining)
      end

      unquote(index_accumulator)
    end
  end
end
