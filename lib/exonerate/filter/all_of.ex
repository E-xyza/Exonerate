defmodule Exonerate.Filter.AllOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  defstruct [:context, :schemas]

  alias Exonerate.Validator
  alias Exonerate.Type

  @impl true
  def parse(validator = %Validator{}, %{"allOf" => s}) do

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(
        validator.schema,
        ["#{&1}", "allOf" | validator.pointer],
        authority: validator.authority))

    types = schemas
    |> Enum.map(&(&1.types))
    |> Enum.map(&Map.new(&1, fn {k, v} -> {k, nil} end))
    |> Enum.reduce(&Type.intersection/2)

    module = %__MODULE__{context: validator, schemas: schemas}

    %{validator |
      types: types,
      children: [module | validator.children],
      distribute: [module | validator.distribute]}
  end

  def distribute(filter, value_ast, path_ast) do
    quote do
      unquote(fun(filter))(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(filter = %__MODULE__{}) do
    calls = Enum.map(filter.schemas, &quote do
      unquote(Validator.to_fun(&1))(value, path)
    end)

    [quote do
      defp unquote(fun(filter))(value, path) do
        unquote_splicing(calls)
      end
    end | Enum.map(filter.schemas, &Validator.compile/1)]
  end

  defp fun(filter) do
    filter.context
    |> Validator.jump_into("allOf")
    |> Validator.to_fun
  end
end
