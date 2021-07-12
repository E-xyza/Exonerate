defmodule Exonerate.Filter.Contains do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :contains]

  def parse(artifact = %{context: context}, %{"contains" => schema}) do
    schema = Validator.parse(context.schema, ["contains" | context.pointer], authority: context.authority)

    %{artifact |
      needs_enum: true,
      enum_pipeline: [{fun(artifact, ":reduce"), []} | artifact.enum_pipeline],
      post_enum_pipeline: [{fun(artifact), []} | artifact.post_enum_pipeline],
      enum_init: Map.put(artifact.enum_init, :contains, false),
      filters: [%__MODULE__{context: artifact.context, contains: schema} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{contains: contains}) do

    contains_fn = Validator.compile(contains)

    {[], [
      quote do
        defp unquote(fun(filter, ":reduce"))(acc, {path, item}) do
          try do
            unquote(fun(filter))(item, path)
            # yes, it has been seen
            %{acc | contains: true}
          catch
            # don't update the "contains" value
            {:error, list} when is_list(list) ->
              acc
          end
        end
        defp unquote(fun(filter))(acc = %{contains: true}, {_path, _array}), do: acc
        defp unquote(fun(filter))(_, {path, array}) do
          Exonerate.mismatch(array, path)
        end

        unquote(contains_fn)
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
