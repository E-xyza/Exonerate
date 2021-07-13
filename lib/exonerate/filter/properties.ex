defmodule Exonerate.Filter.Properties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :children]

  def parse(artifact = %{context: context}, %{"properties" => properties})  do
    children = Map.new(
      properties,
      fn {k, _} ->
        {k, Validator.parse(
        context.schema,
        [k, "properties" | context.pointer],
        authority: context.authority)}
      end)

    %{artifact |
      iterate: true,
      filters: [%__MODULE__{context: context, children: children} | artifact.filters],
      kv_pipeline: [{fun(artifact), []} | artifact.kv_pipeline]
    }
  end

  def compile(filter = %__MODULE__{children: children}) do
    {guarded_clauses, tests} = children
    |> Enum.map(fn {k, v} ->
      {quote do
        defp unquote(fun(filter))(_, {path, unquote(k), v}) do
          unquote(fun(filter, k))(v, Path.join(path, unquote(k)))
          true
        end
      end,
      Validator.compile(v)}
    end)
    |> Enum.unzip


    {[], guarded_clauses ++ [quote do
      defp unquote(fun(filter))(seen, {_path, _key, _value}) do
        seen
      end
    end] ++ tests}
  end

  # TODO: generalize this.
  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("properties")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("properties")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
