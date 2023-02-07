defmodule Exonerate.Filter.Then do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema]

  alias Exonerate.Filter.UnevaluatedHelper
  alias Exonerate.Context

  @impl true
  def parse(context, schema = %{"then" => _}) do
    evaluated_tokens =
      schema
      |> UnevaluatedHelper.token()
      |> List.wrap()
      |> Kernel.++(context.evaluated_tokens)

    schema =
      Context.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "then"),
        authority: context.authority,
        format: context.format,
        draft: context.draft,
        evaluated_tokens: evaluated_tokens
      )

    module = %__MODULE__{context: context, schema: schema}

    %{context | children: [module | context.children], then: true}
  end

  def compile(filter = %__MODULE__{}) do
    [Context.compile(filter.schema)]
  end
end
