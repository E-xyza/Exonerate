defmodule Exonerate.Filter.Contains do
  @moduledoc false
  
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :contains, :min_contains]

  def parse(artifact, %{"contains" => _, "minContains" => 0}), do: artifact

  def parse(artifact = %{context: context}, %{"contains" => _}) do
    schema =
      Validator.parse(
        context.schema,
        ["contains" | context.pointer],
        authority: context.authority,
        format_options: context.format_options)

    filter = %__MODULE__{
      context: artifact.context,
      contains: schema,
      min_contains: is_map_key(schema, "minContains")}

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun(artifact, ["contains", ":reduce"]) | artifact.accumulator_pipeline],
      post_reduce_pipeline: [fun(artifact, "contains") | artifact.post_reduce_pipeline],
      accumulator_init: Map.put_new(artifact.accumulator_init, :contains, 0),
      filters: [filter | artifact.filters]}
  end

  def compile(filter = %__MODULE__{contains: contains}) do

    rest = if filter.min_contains do
      quote do end
    else
      quote do
        defp unquote(fun(filter, "contains"))(%{contains: 0}, {path, array}) do
          Exonerate.mismatch(array, path)
        end
        defp unquote(fun(filter, "contains"))(acc, {_path, _array}), do: acc
      end
    end

    {[], [
      quote do
        defp unquote(fun(filter, ["contains", ":reduce"]))(acc, {path, item}) do
          try do
            unquote(fun(filter, "contains"))(item, path)
            # yes, it has been seen
            %{acc | contains: acc.contains + 1}
          catch
            # don't update the "contains" value
            {:error, list} when is_list(list) ->
              acc
          end
        end
        unquote(rest)
        unquote(Validator.compile(contains))
      end
    ]}
  end
end
