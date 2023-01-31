defmodule Exonerate.Filter.Then do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema]

  alias Exonerate.Validator

  @impl true
  def parse(context = %Validator{}, %{"then" => _}) do
    schema =
      Validator.parse(
        context.schema,
        JsonPointer.traverse(context.pointer, "then"),
        authority: context.authority,
        format: context.format,
        draft: context.draft
      )

    module = %__MODULE__{context: context, schema: schema}

    %{context | children: [module | context.children], then: true}
  end

  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end
end
