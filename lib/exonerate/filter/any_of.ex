defmodule Exonerate.Filter.AnyOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schemas, :evaluated_tokens]

  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Context

  @impl true
  def parse(context, schema = %{"anyOf" => s}) do
    evaluated_tokens =
      schema
      |> UnevaluatedHelper.token()
      |> List.wrap()
      |> Kernel.++(context.evaluated_tokens)

    schemas =
      Enum.map(
        0..(length(s) - 1),
        &Context.parse(
          context.schema,
          JsonPointer.traverse(context.pointer, ["anyOf", "#{&1}"]),
          authority: context.authority,
          format: context.format,
          draft: context.draft,
          evaluated_tokens: evaluated_tokens
        )
      )

    module = %__MODULE__{
      context: context,
      schemas: schemas,
      evaluated_tokens: evaluated_tokens
    }

    %{
      context
      | #  types: types,
        children: [module | context.children],
        combining: [module | context.combining]
    }
  end

  defmacro single_traverse(fun, value_ast, path_ast, token_list) do
    # note we're using a specialized function that will trap throws.
    quote do
      require Exonerate.Filter.UnevaluatedHelper
      token_map = Exonerate.Filter.UnevaluatedHelper.fetch_tokens(unquote(token_list))

      case unquote(fun)({unquote(value_ast), unquote(path_ast)}) do
        :ok ->
          new_tokens_map =
            unquote(token_list)
            |> Exonerate.Filter.UnevaluatedHelper.fetch_tokens()
            |> Enum.reduce(token_map, fn {key, value}, acc ->
              Map.update!(acc, key, &MapSet.union(&1, value))
            end)

          Exonerate.Filter.UnevaluatedHelper.restore_tokens(unquote(token_list), new_tokens_map)
          :ok

        error = {:error, _} ->
          Exonerate.Filter.UnevaluatedHelper.purge_tokens(unquote(token_list))
          Exonerate.Filter.UnevaluatedHelper.restore_tokens(unquote(token_list), token_map)
          error
      end
    end
  end

  # in the case where we don't do a full traverse, we can optimize this with a
  # quit-early clause.
  def combining(filter = %__MODULE__{evaluated_tokens: []}, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, [])

    quote do
      result =
        try do
          Exonerate.pipeline([], {unquote(value_ast), unquote(path_ast)}, unquote(funs))
        catch
          :ok -> :ok
        end

      case result do
        :ok ->
          :ok

        list when is_list(list) ->
          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "anyOf",
            failures: Enum.reverse(list)
          )
      end
    end
  end

  # if we have unevaluated tokens analysis we will need to run a full traversal
  def combining(filter = %__MODULE__{evaluated_tokens: tokens}, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, [])

    traversals =
      Enum.map(funs, fn fun ->
        quote do
          Exonerate.Filter.AnyOf.single_traverse(
            unquote(fun),
            unquote(value_ast),
            unquote(path_ast),
            unquote(tokens)
          )
        end
      end)

    quote do
      require Exonerate.Filter.AnyOf
      result = unquote(traversals)

      if Enum.any?(result, &(&1 === :ok)) do
        :ok
      else
        failures = Enum.map(result, fn {:error, list} -> list end)

        Exonerate.mismatch(unquote(value_ast), unquote(path_ast),
          guard: "anyOf",
          failures: failures
        )
      end
    end
  end

  def compile(filter = %__MODULE__{evaluated_tokens: []}) do
    Enum.flat_map(filter.schemas, fn schema ->
      [
        quote do
          defp unquote([])(fail_so_far, {value, path}) do
            result =
              try do
                unquote([])(value, path)
              catch
                {:error, list} -> list
              end

            case result do
              :ok -> throw(:ok)
              list when is_list(list) -> [list | fail_so_far]
            end
          end
        end,
        Context.compile(schema)
      ]
    end)
  end

  def compile(filter = %__MODULE__{evaluated_tokens: tokens}) do
    Enum.flat_map(filter.schemas, fn schema ->
      [
        quote do
          defp unquote([])({value, path}) do
            result =
              try do
                unquote([])(value, path)
              catch
                error = {:error, _} -> error
              end
          end
        end,
        Context.compile(schema)
      ]
    end)
  end
end
