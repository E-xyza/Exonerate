defmodule Exonerate.Filter.Else do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema]

  alias Exonerate.Validator

  @impl true
  def parse(context = %Validator{}, %{"else" => _}) do
    schema =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "else"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    module = %__MODULE__{context: context, schema: schema}

    %{context | children: [module | context.children], else: true}
  end

  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end
end
