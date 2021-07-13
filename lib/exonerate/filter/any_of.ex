defmodule Exonerate.Filter.AnyOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schemas]

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  @impl true
  def parse(validator = %Validator{}, %{"anyOf" => s}) do

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(
        validator.schema,
        ["#{&1}", "anyOf" | validator.pointer],
        authority: validator.authority))

    # CONSIDER OPTING-IN TO THIS OPTIMIZATION.  NOTE IT BREAKS ERROR PATH REPORTING.
    #types = schemas
    #|> Enum.map(&(&1.types))
    #|> Enum.map(&Map.new(&1, fn {k, _} -> {k, nil} end))
    #|> Enum.reduce(&Type.intersection/2)

    module = %__MODULE__{context: validator, schemas: schemas}

    %{validator |
    #  types: types,
      children: [module | validator.children],
      combining: [module | validator.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, &fun(&1, []))
    quote do
      case Exonerate.pipeline(0, {unquote(value_ast), unquote(path_ast)}, unquote(funs)) do
        0 -> Exonerate.mismatch(unquote(value_ast), unquote(path_ast), guard: "anyOf")
        _ -> :ok
      end
    end
  end

  def compile(filter = %__MODULE__{}) do
    #calls = Enum.map(filter.schemas, &quote do
    #  unquote(Validator.to_fun(&1))(value, path)
    #end)

    Enum.flat_map(filter.schemas, fn schema -> [
      quote do
        defp unquote(fun(schema, []))(acc, {value, path}) do
          try do
            unquote(fun(schema, []))(value, path)
            acc + 1
          catch
            error = {:error, list} when is_list(list) -> acc
          end
        end
      end,
      Validator.compile(schema)]
    end)
  end
end
