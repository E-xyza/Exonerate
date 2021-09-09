defmodule Exonerate.Filter.OneOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :schemas]

  @impl true
  def parse(context = %Validator{}, %{"oneOf" => s}) do

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(
        context.schema,
        ["#{&1}", "oneOf" | context.pointer],
        authority: context.authority,
        format: context.format,
        draft: context.draft))

    # CONSIDER OPTING-IN TO TYPE OPTIMIZATION.  NOTE IT BREAKS ERROR PATH REPORTING.

    module = %__MODULE__{context: context, schemas: schemas}

    %{context |
    #  types: types,
      children: [module | context.children],
      combining: [module | context.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, &fun(&1, []))
    quote do
      case Exonerate.pipeline({0, [], []}, {unquote(value_ast), unquote(path_ast)}, unquote(funs)) do
        {1, _, _} -> :ok
        {0, _, errors} ->
          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "oneOf",
            reason: "no matches",
            failures: Enum.reverse(errors))
        {_, matches, errors} ->
          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "oneOf",
            reason: "multiple matches",
            failures: Enum.reverse(errors),
            matches: Enum.reverse(matches))
      end
    end
  end

  def compile(filter = %__MODULE__{}) do
    Enum.flat_map(filter.schemas, fn schema->
      local_path =
        schema
        |> fun([])
        |> Exonerate.fun_to_path()

      [
        quote do
          defp unquote(fun(schema, []))({count, matches, errors}, {value, path}) do
            try do
              unquote(fun(schema, []))(value, path)
              {count + 1, [unquote(local_path) | matches], errors}
            catch
              error = {:error, list} when is_list(list) ->
              {count, matches, [list | errors]}
            end
          end
        end,
        Validator.compile(schema)
      ]
    end)
  end
end
