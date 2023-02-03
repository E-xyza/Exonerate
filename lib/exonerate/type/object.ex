defmodule Exonerate.Type.Object do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Tools
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [
    :context,
    evaluated_tokens: [],
    iterate: false,
    filters: [],
    kv_pipeline: [],
    pipeline: []
  ]

  @type t :: %__MODULE__{}

  # note:
  # additionalProperties MUST precede patternProperties
  @validator_filters ~w(unevaluatedProperties required maxProperties minProperties
    additionalProperties properties patternProperties dependentRequired
    dependentSchemas dependencies propertyNames)

  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  # draft <= 7 refs inhibit type-based analysis
  def parse(validator = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: validator}
  end

  def parse(validator = %Validator{}, schema) do
    evaluated_tokens =
      schema
      |> UnevaluatedHelper.token()
      |> List.wrap()

    %__MODULE__{context: validator, evaluated_tokens: evaluated_tokens}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)

      artifact, _ ->
        artifact
    end)
  end

  @spec compile(t) :: Macro.t()
  def compile(artifact) do
    token = List.first(artifact.evaluated_tokens)

    unevaluated_start =
      List.wrap(
        if token do
          quote bind_quoted: [evaluated_tokens: token] do
            unevaluated_previous = Process.put(evaluated_tokens, MapSet.new())
          end
        end
      )

    iteration =
      List.wrap(
        if artifact.iterate do
          [
            quote do
              Enum.each(object, fn
                {k, v} ->
                  Exonerate.pipeline(false, {path, k, v}, unquote(artifact.kv_pipeline))
              end)
            end
          ]
        end
      )

    combining =
      Validator.combining(
        artifact.context,
        quote do
          object
        end,
        quote do
          path
        end
      )

    if token do
      filter = fun(artifact, "unevaluatedProperties")

      quote do
        defp unquote(fun(artifact, []))(object, path) when is_map(object) do
          Exonerate.pipeline(object, path, unquote(artifact.pipeline))
          unquote_splicing(unevaluated_start ++ iteration ++ combining)

          evaluated =
            unquote(token)
            |> Process.get()
            |> Enum.to_list()

          object
          |> Map.drop(evaluated)
          |> Enum.each(fn {k, v} ->
            unquote(filter)(v, Path.join(path, k))
          end)
        end
      end
    else
      quote do
        defp unquote(fun(artifact, []))(object, path) when is_map(object) do
          Exonerate.pipeline(object, path, unquote(artifact.pipeline))
          unquote_splicing(unevaluated_start ++ iteration ++ combining)
        end
      end
    end
  end
end
