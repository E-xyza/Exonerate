defmodule Exonerate.Filter.Pattern do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :pattern]

  def parse(artifact = %Exonerate.Type.String{}, %{"pattern" => pattern}) do
    %{artifact |
      pipeline: [fun(artifact) | artifact.pipeline],
      filters: [%__MODULE__{context: artifact.context, pattern: pattern} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{}) do
    {[quote do
      defp unquote(fun(filter))(string, path) do
        unless Regex.match?(sigil_r(<<unquote(filter.pattern)>>, []), string) do
          Exonerate.mismatch(string, path)
        end
        string
      end
    end], []}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("pattern")
    |> Validator.to_fun
  end
end
