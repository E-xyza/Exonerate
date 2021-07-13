defmodule Exonerate.Filter.Then do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :schema]

  alias Exonerate.Validator

  @impl true
  def parse(validator = %Validator{}, %{"then" => _}) do

    schema = Validator.parse(
      validator.schema,
      ["then" | validator.pointer],
      authority: validator.authority)

    module = %__MODULE__{context: validator, schema: schema}

    %{validator | children: [module | validator.children], then: true}
  end

  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end
end
