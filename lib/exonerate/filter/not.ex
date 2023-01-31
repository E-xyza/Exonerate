defmodule Exonerate.Filter.Not do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, :schema]

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  @impl true
  def parse(context = %Validator{}, %{"not" => _}) do
    schema =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "not"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    module = %__MODULE__{context: context, schema: schema}

    %{context | children: [module | context.children], combining: [module | context.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    quote do
      negated =
        try do
          unquote(fun(filter, "not"))(unquote(value_ast), unquote(path_ast))
        catch
          error = {:error, list} when is_list(list) -> error
        end

      case negated do
        :ok ->
          Exonerate.mismatch(unquote(value_ast), unquote(path_ast), guard: "not")

        {:error, list} ->
          :ok
      end
    end
  end

  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end
end
