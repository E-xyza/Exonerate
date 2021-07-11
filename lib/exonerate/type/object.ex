defmodule Exonerate.Type.Object do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  defstruct [:context, filters: [], pipeline: [], arrows: []]
  @type t :: %__MODULE__{}

  @validator_filters ~w(properties)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  def parse(validator = %Validator{}, schema) do
    %__MODULE__{context: validator}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)
      artifact, _ -> artifact
    end)
  end

  @spec compile(t) :: Macro.t
  def compile(artifact) do
    arrows = Enum.map(artifact.arrows, fn
      {key, target} ->
        Tools.map_arrow(key, Tools.variable(:value), call(target, Tools.variable(:value), key))
    end)

    properties_fun = {:fn, [], arrows ++ [Tools.map_arrow(Tools.variable(:_), Tools.variable(:_), :ok)]}

    quote do
      defp unquote(Validator.to_fun(artifact.context))(object, path) when is_map(object) do
        Exonerate.pipeline(object, path, unquote(artifact.pipeline))
        Enum.each(object, unquote(properties_fun))
      end
    end
  end

  defp call(fun, value_ast, nexthop) do
    quote do
      unquote(fun)(unquote(value_ast), Path.join(path, unquote(nexthop)))
    end
  end
end
