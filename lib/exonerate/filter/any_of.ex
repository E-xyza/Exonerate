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
        authority: validator.authority,
        format: validator.format))

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
      result = try do
        Exonerate.pipeline([], {unquote(value_ast), unquote(path_ast)}, unquote(funs))
      catch
        :ok -> :ok
      end

      case result do
        :ok -> :ok
        list when is_list(list) ->
          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "anyOf",
            failures: Enum.reverse(list))
      end
    end
  end

  def compile(filter = %__MODULE__{}) do
    Enum.flat_map(filter.schemas, fn schema -> [
      quote do
        defp unquote(fun(schema, []))(fail_so_far, {value, path}) do
          result = try do
            unquote(fun(schema, []))(value, path)
          catch
            {:error, list} -> list
          end

          case result do
            :ok -> throw :ok
            list when is_list(list) -> [list | fail_so_far]
          end
        end
      end,
      Validator.compile(schema)]
    end)
  end
end
