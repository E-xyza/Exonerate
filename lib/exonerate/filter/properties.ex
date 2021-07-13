defmodule Exonerate.Filter.Properties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

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
      kv_pipeline: [fun(artifact, "properties") | artifact.kv_pipeline]
    }
  end

  def compile(filter = %__MODULE__{children: children}) do
    {guarded_clauses, tests} = children
    |> Enum.map(fn {k, v} ->
      {quote do
        defp unquote(fun(filter, "properties"))(_, {path, unquote(k), v}) do
          unquote(fun(filter, ["properties", k]))(v, Path.join(path, unquote(k)))
          true
        end
      end,
      Validator.compile(v)}
    end)
    |> Enum.unzip


    {[], guarded_clauses ++ [quote do
      defp unquote(fun(filter, "properties"))(seen, {_path, _key, _value}) do
        seen
      end
    end] ++ tests}
  end
end
