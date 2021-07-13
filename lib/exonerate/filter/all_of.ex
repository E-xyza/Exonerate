defmodule Exonerate.Filter.AllOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schemas]

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  @impl true
  def parse(validator = %Validator{}, %{"allOf" => s}) do

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(
        validator.schema,
        ["#{&1}", "allOf" | validator.pointer],
        authority: validator.authority))

    # CONSIDER OPTING-IN TO THIS OPTIMIZATION.  NOTE IT BREAKS ERROR PATH REPORTING.
    #types = schemas
    #|> Enum.map(&(&1.types))
    #|> Enum.map(&Map.new(&1, fn {k, _} -> {k, nil} end))
    #|> Enum.reduce(&Type.intersection/2)

    module = %__MODULE__{context: validator, schemas: schemas}

    %{validator |
      children: [module | validator.children],
      combining: [module | validator.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    quote do
      unquote(fun(filter, "allOf"))(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(filter = %__MODULE__{}) do
    calls = Enum.map(filter.schemas, &quote do
      unquote(fun(&1, []))(value, path)
    end)

    [quote do
      defp unquote(fun(filter, "allOf"))(value, path) do
        unquote_splicing(calls)
      end
    end | Enum.map(filter.schemas, &Validator.compile/1)]
  end
end
