defmodule Exonerate.Filter.Contains do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :contains, :min_contains]

  def parse(artifact, %{"contains" => _, "minContains" => 0}), do: artifact

  def parse(artifact = %{context: context}, %{"contains" => _}) do
    schema =
      Validator.parse(context.schema, ["contains" | context.pointer], authority: context.authority)

    filter = %__MODULE__{
      context: artifact.context,
      contains: schema,
      min_contains: is_map_key(schema, "minContains")}

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun(artifact, ":reduce") | artifact.accumulator_pipeline],
      post_reduce_pipeline: [fun(artifact) | artifact.post_reduce_pipeline],
      accumulator_init: Map.put_new(artifact.accumulator_init, :contains, 0),
      filters: [filter | artifact.filters]}
  end

  def compile(filter = %__MODULE__{contains: contains}) do

    rest = if filter.min_contains do
      quote do end
    else
      quote do
        defp unquote(fun(filter))(%{contains: 0}, {path, array}) do
          Exonerate.mismatch(array, path)
        end
        defp unquote(fun(filter))(acc, {_path, _array}), do: acc
      end
    end

    {[], [
      quote do
        defp unquote(fun(filter, ":reduce"))(acc, {path, item}) do
          try do
            unquote(fun(filter))(item, path)
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

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("contains")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, nexthop) do
    filter_or_artifact.context
    |> Validator.jump_into("contains")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
