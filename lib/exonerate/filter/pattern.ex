defmodule Exonerate.Filter.Pattern do
  @moduledoc false
  
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :pattern]

  def parse(artifact = %Exonerate.Type.String{}, %{"pattern" => pattern}) do
    %{artifact |
      pipeline: [fun(artifact, "pattern") | artifact.pipeline],
      filters: [%__MODULE__{context: artifact.context, pattern: pattern} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{}) do
    {[quote do
      defp unquote(fun(filter, "pattern"))(string, path) do
        unless Regex.match?(sigil_r(<<unquote(filter.pattern)>>, []), string) do
          Exonerate.mismatch(string, path)
        end
        string
      end
    end], []}
  end
end
