defmodule Exonerate.Filter.If do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema, :then, :else]

  alias Exonerate.Validator
  alias Exonerate.Type

  @impl true
  def parse(validator = %Validator{}, %{"if" => _}) do

    schema = Validator.parse(
      validator.schema,
      ["if" | validator.pointer],
      authority: validator.authority)

    module = %__MODULE__{context: validator, schema: schema, then: validator.then, else: validator.else}

    %{validator |
      children: [module | validator.children],
      combining: [module | validator.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    quote do
      unquote(fun(filter, ":test"))(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(filter = %__MODULE__{}) do
    then_clause = if filter.then do
      quote do
        unquote(fun0(filter, "then"))(value, path)
      end
    else
      :ok
    end

    else_clause = if filter.else do
      quote do
        unquote(fun0(filter, "else"))(value, path)
      end
    else
      :ok
    end

    [quote do
      defp unquote(fun(filter, ":test"))(value, path) do
        conditional = try do
          unquote(fun(filter))(value, path)
        catch
          error = {:error, list} when is_list(list) -> error
        end

        case conditional do
          :ok -> unquote(then_clause)
          {:error, _} -> unquote(else_clause)
        end
      end
      unquote(Validator.compile(filter.schema))
    end]
  end

  defp fun0(filter, nexthop) do
    filter.context
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end

  defp fun(filter) do
    filter.context
    |> Validator.jump_into("if")
    |> Validator.to_fun
  end

  defp fun(filter, nexthop) do
    filter.context
    |> Validator.jump_into("if")
    |> Validator.jump_into(nexthop)
    |> Validator.to_fun
  end
end
