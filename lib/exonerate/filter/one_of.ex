defmodule Exonerate.Filter.OneOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Context

  defstruct [:context, :schemas, :evaluated_tokens]

  @impl true
  def parse(context, schema = %{"oneOf" => s}) do
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
          JsonPointer.traverse(context.pointer, ["oneOf", "#{&1}"]),
          authority: context.authority,
          format: context.format,
          draft: context.draft,
          evaluated_tokens: evaluated_tokens
        )
      )

    module = %__MODULE__{context: context, schemas: schemas, evaluated_tokens: evaluated_tokens}

    %{
      context
      | #  types: types,
        children: [module | context.children],
        combining: [module | context.combining]
    }
  end

  def combining(filter, value_ast, path_ast) do
    funs = Enum.map(filter.schemas, [])

    quote do
      case Exonerate.pipeline({0, [], []}, {unquote(value_ast), unquote(path_ast)}, unquote(funs)) do
        {1, _, _} ->
          :ok

        {0, _, errors} ->
          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "oneOf",
            reason: "no matches",
            failures: Enum.reverse(errors)
          )

        {_, matches, errors} ->
          require Exonerate.Filter.UnevaluatedHelper
          Exonerate.Filter.UnevaluatedHelper.purge_tokens(unquote(filter.evaluated_tokens))

          Exonerate.mismatch(
            unquote(value_ast),
            unquote(path_ast),
            guard: "oneOf",
            reason: "multiple matches",
            failures: Enum.reverse(errors),
            matches: Enum.reverse(matches)
          )
      end
    end
  end

  def compile(filter = %__MODULE__{evaluated_tokens: []}) do
    Enum.flat_map(filter.schemas, fn schema ->
      local_path =
        schema
        |> Exonerate.fun_to_path()

      [
        quote do
          defp unquote([])({count, matches, errors}, {value, path}) do
            try do
              unquote([])(value, path)
              {count + 1, [unquote(local_path) | matches], errors}
            catch
              error = {:error, list} when is_list(list) ->
                {count, matches, [list | errors]}
            end
          end
        end,
        Context.compile(schema)
      ]
    end)
  end

  def compile(filter = %__MODULE__{evaluated_tokens: tokens}) do
    Enum.flat_map(filter.schemas, fn schema ->
      local_path =
        schema
        |> Exonerate.fun_to_path()

      [
        quote do
          defp unquote([])({count, matches, errors}, {value, path}) do
            require Exonerate.Filter.UnevaluatedHelper
            token_map = Exonerate.Filter.UnevaluatedHelper.fetch_tokens(unquote(tokens))

            try do
              unquote([])(value, path)

              new_tokens_map =
                unquote(tokens)
                |> Exonerate.Filter.UnevaluatedHelper.fetch_tokens()
                |> Enum.reduce(token_map, fn {key, value}, acc ->
                  Map.update!(acc, key, &MapSet.union(&1, value))
                end)

              Exonerate.Filter.UnevaluatedHelper.restore_tokens(unquote(tokens), new_tokens_map)

              {count + 1, [unquote(local_path) | matches], errors}
            catch
              error = {:error, list} when is_list(list) ->
                Exonerate.Filter.UnevaluatedHelper.purge_tokens(unquote(tokens))
                Exonerate.Filter.UnevaluatedHelper.restore_tokens(unquote(tokens), token_map)
                {count, matches, [list | errors]}
            end
          end
        end,
        Context.compile(schema)
      ]
    end)
  end
end
