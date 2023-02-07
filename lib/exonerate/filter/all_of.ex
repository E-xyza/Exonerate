defmodule Exonerate.Filter.AllOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schemas]

  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Context

  import Context, only: [fun: 2]

  @impl true
  def parse(context = %Context{}, schema = %{"allOf" => s}) do
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
          JsonPointer.traverse(context.pointer, ["allOf", "#{&1}"]),
          authority: context.authority,
          format: context.format,
          draft: context.draft,
          evaluated_tokens: evaluated_tokens
        )
      )

    # CONSIDER OPTING-IN TO THIS OPTIMIZATION.  NOTE IT BREAKS ERROR PATH REPORTING.
    # types = schemas
    # |> Enum.map(&(&1.types))
    # |> Enum.map(&Map.new(&1, fn {k, _} -> {k, nil} end))
    # |> Enum.reduce(&Type.intersection/2)

    module = %__MODULE__{context: context, schemas: schemas}

    %{
      context
      | children: [module | context.children],
        combining: [module | context.combining]
    }
  end

  def combining(filter, value_ast, path_ast) do
    quote do
      unquote(fun(filter, "allOf"))(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(filter = %__MODULE__{}) do
    calls =
      Enum.map(
        filter.schemas,
        &quote do
          unquote(fun(&1, []))(value, path)
        end
      )

    [
      quote do
        defp unquote(fun(filter, "allOf"))(value, path) do
          (unquote_splicing(calls))
        end
      end
      | Enum.map(filter.schemas, &Context.compile/1)
    ]
  end
end
