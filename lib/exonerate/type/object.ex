defmodule Exonerate.Type.Object do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Filter.UnevaluatedProperties
  alias Exonerate.Tools
  alias Exonerate.Context

  import Context, only: [fun: 2]

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
  @context_filters ~w(unevaluatedProperties required maxProperties minProperties
    additionalProperties properties patternProperties dependentRequired
    dependentSchemas dependencies propertyNames)

  @context_modules Map.new(@context_filters, &{&1, Filter.from_string(&1)})

  # draft <= 7 refs inhibit type-based analysis
  def parse(context = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: context}
  end

  def parse(context = %Context{}, schema) do
    evaluated_tokens =
      schema
      |> UnevaluatedHelper.token()
      |> List.wrap()

    %__MODULE__{context: context, evaluated_tokens: evaluated_tokens}
    |> Tools.collect(@context_filters, fn
      filter, filter when is_map_key(schema, filter) ->
        Filter.parse(filter, @context_modules[filter], schema)

      filter, _ ->
        filter
    end)
  end

  @spec compile(t) :: Macro.t()
  def compile(filter) do
    token = List.first(filter.evaluated_tokens)

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
        if filter.iterate do
          [
            quote do
              Enum.each(object, fn
                {k, v} ->
                  Exonerate.pipeline(false, {path, k, v}, unquote(filter.kv_pipeline))
              end)
            end
          ]
        end
      )

    combining =
      Context.combining(
        filter.context,
        quote do
          object
        end,
        quote do
          path
        end
      )

    case {token, unevaluated_false?(filter)} do
      {nil, _} ->
        quote do
          defp unquote(fun(filter, []))(object, path) when is_map(object) do
            Exonerate.pipeline(object, path, unquote(filter.pipeline))
            unquote_splicing(unevaluated_start ++ iteration ++ combining)
          end
        end

      {_, true} ->
        quote do
          defp unquote(fun(filter, []))(object, path) when is_map(object) do
            Exonerate.pipeline(object, path, unquote(filter.pipeline))
            unquote_splicing(unevaluated_start ++ iteration ++ combining)

            evaluated =
              unquote(token)
              |> Process.get()
              |> Enum.to_list()

            test = Map.drop(object, evaluated)

            unless test === %{} do
              Exonerate.mismatch(test, Path.join(path, "unevaluatedProperties"))
            end

            :ok
          end
        end

      {_, false} ->
        filter = fun(filter, "unevaluatedProperties")

        quote do
          defp unquote(fun(filter, []))(object, path) when is_map(object) do
            Exonerate.pipeline(object, path, unquote(filter.pipeline))
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
    end
  end

  defp unevaluated_false?(filter) do
    Enum.any?(filter.filters, &match?(%UnevaluatedProperties{child: false}, &1))
  end
end
