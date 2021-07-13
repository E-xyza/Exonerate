defmodule Exonerate.Filter.Else do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema]

  alias Exonerate.Validator

  @impl true
  def parse(validator = %Validator{}, %{"else" => _}) do

    schema = Validator.parse(
      validator.schema,
      ["else" | validator.pointer],
      authority: validator.authority)

    module = %__MODULE__{context: validator, schema: schema}

    %{validator | children: [module | validator.children], else: true}
  end

  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end
end
