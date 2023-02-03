defmodule Exonerate.Filter.If do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :schema, :then, :else, :evaluated_tokens]

  @impl true
  def parse(context = %Validator{}, schema = %{"if" => _}) do
    evaluated_tokens =
      schema
      |> UnevaluatedHelper.token()
      |> List.wrap()
      |> Kernel.++(context.evaluated_tokens)

    schema =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "if"),
        authority: context.authority,
        format: context.format,
        draft: context.draft,
        evaluated_tokens: evaluated_tokens
      )

    module = %__MODULE__{context: context, schema: schema, then: context.then, else: context.else, evaluated_tokens: evaluated_tokens}

    %{context | children: [module | context.children], combining: [module | context.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    quote do
      unquote(fun(filter, ["if", ":test"]))(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(filter = %__MODULE__{}) do
    then_clause =
      if filter.then do
        quote do
          unquote(fun(filter, "then"))(value, path)
        end
      else
        :ok
      end

    else_clause =
      if filter.else do
        quote do
          unquote(fun(filter, "else"))(value, path)
        end
      else
        :ok
      end

    code =
      case filter.evaluated_tokens do
        [] ->
          quote do
            defp unquote(fun(filter, ["if", ":test"]))(value, path) do
              conditional =
                try do
                  unquote(fun(filter, "if"))(value, path)
                catch
                  error = {:error, list} when is_list(list) -> error
                end

              case conditional do
                :ok -> unquote(then_clause)
                {:error, _} -> unquote(else_clause)
              end
            end
          end

        tokens ->
          quote do
            defp unquote(fun(filter, ["if", ":test"]))(value, path) do
              require Exonerate.Filter.UnevaluatedHelper
              token_map = Exonerate.Filter.UnevaluatedHelper.fetch_tokens(unquote(tokens))

              conditional =
                try do
                  unquote(fun(filter, "if"))(value, path)
                catch
                  error = {:error, list} when is_list(list) ->
                    error
                end

              result =
                case conditional do
                  :ok ->
                    unquote(then_clause)

                  {:error, _} ->
                    Exonerate.Filter.UnevaluatedHelper.purge_tokens(unquote(tokens))
                    unquote(else_clause)
                end

              new_tokens_map =
                unquote(tokens)
                |> Exonerate.Filter.UnevaluatedHelper.fetch_tokens()
                |> Enum.reduce(token_map, fn {key, value}, acc ->
                  Map.update!(acc, key, &MapSet.union(&1, value))
                end)

              Exonerate.Filter.UnevaluatedHelper.restore_tokens(unquote(tokens), new_tokens_map)

              result
            end
          end
      end

    [code, Validator.compile(filter.schema)]
  end
end
