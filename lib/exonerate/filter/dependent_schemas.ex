defmodule Exonerate.Filter.DependentSchemas do
  @moduledoc false

  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of full schema to be applied to the object)

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Validator
  defstruct [:context, :dependencies]

  import Validator, only: [fun: 2]

  def parse(artifact = %Object{context: context}, %{"dependentSchemas" => deps}) do
    deps = deps
    |> Enum.reject(&(elem(&1, 1) == true)) # as an optimization, just ignore {key, true}
    |> Map.new(fn
      {k, false} -> {k, false}  # might be optimizable as a filter.  Not done here.
      {k, schema} when is_map(schema) ->
        {k, Validator.parse(
          context.schema,
          [k, "dependentSchemas" | context.pointer],
          authority: context.authority,
          format: context.format
        )}
    end)

    %{
      artifact |
      pipeline: [fun(artifact, "dependentSchemas") | artifact.pipeline],
      filters: [%__MODULE__{context: context, dependencies: deps} | artifact.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} = deps
    |> Enum.map(fn
      {key, false} ->
        {fun(filter, ["dependentSchemas", key]),
        quote do
          defp unquote(fun(filter, ["dependentSchemas", key]))(value, path) when is_map_key(value, unquote(key)) do
            Exonerate.mismatch(value, Path.join(path, unquote(key)))
          end
          defp unquote(fun(filter, ["dependentSchemas", key]))(value, _), do: value
        end}
      {key, schema} ->
        {fun(filter, ["dependentSchemas", ":" <> key]),
        quote do
          defp unquote(fun(filter, ["dependentSchemas", ":" <> key]))(value, path) when is_map_key(value, unquote(key)) do
            unquote(fun(filter, ["dependentSchemas", key]))(value, path)
          end
          defp unquote(fun(filter, ["dependentSchemas", ":" <> key]))(value, _), do: value
          unquote(Validator.compile(schema))
        end}
    end)
    |> Enum.unzip

    {[], [
      quote do
        defp unquote(fun(filter, "dependentSchemas"))(value, path) do
          Exonerate.pipeline(value, path, unquote(pipeline))
          :ok
        end
      end
    ] ++ children}
  end
end
