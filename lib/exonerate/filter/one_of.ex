defmodule Exonerate.Filter.OneOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, :schemas]

  alias Exonerate.Validator

  @impl true
  def parse(validator = %Validator{}, %{"oneOf" => s}) do

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(
        validator.schema,
        ["#{&1}", "oneOf" | validator.pointer],
        authority: validator.authority))

    # CONSIDER OPTING-IN TO TYPE OPTIMIZATION.  NOTE IT BREAKS ERROR PATH REPORTING.

    module = %__MODULE__{context: validator, schemas: schemas}

    %{validator |
    #  types: types,
      children: [module | validator.children],
      combining: [module | validator.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, &Validator.to_fun(&1))
    quote do
      case Exonerate.pipeline(0, {unquote(value_ast), unquote(path_ast)}, unquote(funs)) do
        1 -> :ok
        _ -> Exonerate.mismatch(unquote(value_ast), unquote(path_ast), guard: "oneOf")
      end
    end
  end

  def compile(filter = %__MODULE__{}) do
    #calls = Enum.map(filter.schemas, &quote do
    #  unquote(Validator.to_fun(&1))(value, path)
    #end)

    Enum.flat_map(filter.schemas, fn schema -> [
      quote do
        defp unquote(Validator.to_fun(schema))(acc, {value, path}) do
          try do
            unquote(Validator.to_fun(schema))(value, path)
            acc + 1
          catch
            error = {:error, list} when is_list(list) -> acc
          end
        end
      end,
      Validator.compile(schema)]
    end)
  end

  defp fun(filter) do
    filter.context
    |> Validator.jump_into("oneOf")
    |> Validator.to_fun
  end
end
