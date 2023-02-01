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
    :unevaluated_token,
    iterate: false,
    filters: [],
    kv_pipeline: [],
    pipeline: []
  ]

  @type t :: %__MODULE__{}

  # note:
  # unevaluatedProperties MUST be the first filter
  # additionalProperties MUST precede patternProperties
  @validator_filters ~w(unevaluatedProperties required maxProperties
    minProperties additionalProperties properties patternProperties
    dependentRequired dependentSchemas dependencies propertyNames)

  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  # draft <= 7 refs inhibit type-based analysis
  def parse(validator = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: validator}
  end

  def parse(validator = %Validator{}, schema) do
    unevaluated_token =
      if Map.has_key?(schema, "unevaluatedProperties") do
        :"unevaluatedProperties-#{:erlang.phash2(schema)}"
      end

    %__MODULE__{context: validator, unevaluated_token: unevaluated_token}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)

      artifact, _ ->
        artifact
    end)
  end

  @spec compile(t) :: Macro.t()
  def compile(artifact) do
    {unevaluated_start, unevaluated_end} =
      if token = artifact.unevaluated_token do
        {[
           quote bind_quoted: [unevaluated_token: token] do
             unevaluated_previous = Process.put(unevaluated_token, MapSet.new())
           end
         ],
         [
           quote bind_quoted: [unevaluated_token: token] do
             if unevaluated_previous do
               Process.put(unevaluated_token, unevaluated_previous)
             else
               Process.delete(unevaluated_token)
             end

             :ok
           end
         ]}
      else
        {[], []}
      end

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

    quote do
      defp unquote(fun(artifact, []))(object, path) when is_map(object) do
        Exonerate.pipeline(object, path, unquote(artifact.pipeline))
        unquote_splicing(unevaluated_start ++ iteration ++ combining ++ unevaluated_end)
      end
    end
  end
end
