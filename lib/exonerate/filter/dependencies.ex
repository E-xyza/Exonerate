defmodule Exonerate.Filter.Dependencies do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Validator
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
      pipeline: [fun(artifact) | artifact.pipeline],
      filters: [%__MODULE__{context: context, dependencies: deps} | artifact.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} = deps
    |> Enum.map(fn
      {key, false} ->
        {fun(filter, key),
        quote do
          defp unquote(fun(filter, key))(value, path) when is_map_key(value, unquote(key)) do
            Exonerate.mismatch(value, Path.join(path, unquote(key)))
          end
          defp unquote(fun(filter, key))(value, _), do: value
        end}
      # one item optimization
      {key, [dependent_key]} ->
        {fun(filter, key),
        quote do
          defp unquote(fun(filter, key))(value, path) when is_map_key(value, unquote(key)) do
            unless is_map_key(value, unquote(dependent_key)) do
              Exonerate.mismatch(value, path, guard: "0")
            end
            value
          end
          defp unquote(fun(filter, key))(value, _), do: value
        end}
      {key, dependent_keys} when is_list(dependent_keys) ->
        {fun(filter, key),
        quote do
          defp unquote(fun(filter, key))(value, path) when is_map_key(value, unquote(key)) do
            unquote(dependent_keys)
            |> Enum.with_index
            |> Enum.each(fn {key, index} ->
              unless is_map_key(value, key), do: Exonerate.mismatch(value, path, guard: to_string(index))
            end)
            value
          end
          defp unquote(fun(filter, key))(value, _), do: value
        end}
      {key, schema} ->
        {fun(filter, ":" <> key),
        quote do
          defp unquote(fun(filter, ":" <> key))(value, path) when is_map_key(value, unquote(key)) do
            unquote(fun(filter,key))(value, path)
          end
          defp unquote(fun(filter, ":" <> key))(value, _), do: value
          unquote(Validator.compile(schema))
        end
        }
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
    |> Validator.jump_into("dependencies")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("dependencies")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
