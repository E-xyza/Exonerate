defmodule Exonerate.Filter.DependentSchemas do
  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of full schema to be applied to the object)

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Validator
  defstruct [:context, :dependencies]

  def parse(artifact = %Object{context: context}, %{"dependentSchemas" => deps}) do
    deps = deps
    |> Enum.reject(&(elem(&1, 1) == true)) # as an optimization, just ignore {key, true}
    |> Map.new(fn
      {k, false} -> {k, false}  # might be optimizable as a filter.  Not done here.
      {k, schema} when is_map(schema) ->
        {k, Validator.parse(
          context.schema,
          [k, "dependentSchemas" | context.pointer],
          authority: context.authority
        )}
    end)

    %{
      artifact |
      pipeline: [{fun(artifact), []} | artifact.pipeline],
      filters: [%__MODULE__{context: context, dependencies: deps} | artifact.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} = deps
    |> Enum.map(fn
      {key, false} ->
        {{fun(filter, key), []},
        quote do
          defp unquote(fun(filter, key))(value, path) when is_map_key(value, unquote(key)) do
            Exonerate.mismatch(value, Path.join(path, unquote(key)))
          end
          defp unquote(fun(filter, key))(value, _), do: value
        end}
      {key, schema} ->
        {{fun(filter, ":" <> key), []},
        quote do
          defp unquote(fun(filter, ":" <> key))(value, path) when is_map_key(value, unquote(key)) do
            unquote(fun(filter,key))(value, path)
          end
          defp unquote(fun(filter, ":" <> key))(value, _), do: value
          unquote(Validator.compile(schema))
        end}
    end)
    |> Enum.unzip

    {[], [
      quote do
        defp unquote(fun(filter))(value, path) do
          Exonerate.pipeline(value, path, unquote(pipeline))
          :ok
        end
      end
    ] ++ children}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("dependentSchemas")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("dependentSchemas")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
