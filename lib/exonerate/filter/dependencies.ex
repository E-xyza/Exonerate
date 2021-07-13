defmodule Exonerate.Filter.Dependencies do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :dependencies]

  def parse(artifact = %Object{context: context}, %{"dependencies" => deps}) do
    deps = deps
    |> Enum.reject(&(elem(&1, 1) == true)) # as an optimization, just ignore {key, true}
    |> Map.new(fn
      {k, false} -> {k, false}  # might be optimizable as a filter.  Not done here.
      {k, list} when is_list(list) ->
        {k, list}
      {k, schema} when is_map(schema) ->
        {k, Validator.parse(
          context.schema,
          [k, "dependencies" | context.pointer],
          authority: context.authority
        )}
    end)

    %{
      artifact |
      pipeline: [fun(artifact, "dependencies") | artifact.pipeline],
      filters: [%__MODULE__{context: context, dependencies: deps} | artifact.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} = deps
    |> Enum.map(fn
      {key, false} ->
        {fun(filter, ["dependencies", key]),
        quote do
          defp unquote(fun(filter, ["dependencies", key]))(value, path) when is_map_key(value, unquote(key)) do
            Exonerate.mismatch(value, Path.join(path, unquote(key)))
          end
          defp unquote(fun(filter, ["dependencies", key]))(value, _), do: value
        end}
      # one item optimization
      {key, [dependent_key]} ->
        {fun(filter, ["dependencies", key]),
        quote do
          defp unquote(fun(filter, ["dependencies", key]))(value, path) when is_map_key(value, unquote(key)) do
            unless is_map_key(value, unquote(dependent_key)) do
              Exonerate.mismatch(value, path, guard: "0")
            end
            value
          end
          defp unquote(fun(filter, ["dependencies", key]))(value, _), do: value
        end}
      {key, dependent_keys} when is_list(dependent_keys) ->
        {fun(filter, ["dependencies", key]),
        quote do
          defp unquote(fun(filter, ["dependencies", key]))(value, path) when is_map_key(value, unquote(key)) do
            unquote(dependent_keys)
            |> Enum.with_index
            |> Enum.each(fn {key, index} ->
              unless is_map_key(value, key), do: Exonerate.mismatch(value, path, guard: to_string(index))
            end)
            value
          end
          defp unquote(fun(filter, ["dependencies", key]))(value, _), do: value
        end}
      {key, schema} ->
        {fun(filter, ["dependencies", ":" <> key]),
        quote do
          defp unquote(fun(filter, ["dependencies", ":" <> key]))(value, path) when is_map_key(value, unquote(key)) do
            unquote(fun(filter, ["dependencies", key]))(value, path)
          end
          defp unquote(fun(filter, ["dependencies", ":" <> key]))(value, _), do: value
          unquote(Validator.compile(schema))
        end
        }
    end)
    |> Enum.unzip

    {[], [
      quote do
        defp unquote(fun(filter, "dependencies"))(value, path) do
          Exonerate.pipeline(value, path, unquote(pipeline))
          :ok
        end
      end
    ] ++ children}
  end
end
