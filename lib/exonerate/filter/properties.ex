defmodule Exonerate.Filter.Properties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :schema]

  def parse(artifact = %{context: context}, %{"properties" => properties})  do
    schema = Map.new(properties, fn
      {property, _} ->
        {property, Validator.parse(context.schema, [property, "properties" | context.pointer], authority: context.authority)}
    end)

    %{artifact |
      pipeline: [{fun(artifact), []} | artifact.pipeline],
      filters: [%__MODULE__{context: artifact.context, schema: schema} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{schema: schema}) do
    {arrows, impls} = schema
    |> Enum.map(
      fn {property, subcontext} ->
        call = &quote do
          unquote(fun(filter, property))(unquote(&1), Path.join(path, unquote(property)))
        end
        
        {
          arrow(property, variable(:value), call.(variable(:value))),
          Validator.compile(subcontext)
        }
      end)
    |> Enum.unzip

    fun = {:fn, [], arrows ++ [arrow(variable(:_), variable(:_), :ok)]}

    {[], [
      quote do
        defp unquote(fun(filter))(object, path) do
          Enum.each(object, unquote(fun))
        end
      end
    ] ++ impls}
  end

  defp variable(v), do: {v, [], Elixir}
  defp arrow(a1, a2, out) do
    {:->, [], [[{a1, a2}], out]}
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
