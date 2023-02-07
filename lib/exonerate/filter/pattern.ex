defmodule Exonerate.Filter.Pattern do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :pattern]

  def parse(filter, %{"pattern" => pattern}) do
    %{
      filter
      | pipeline: ["pattern" | filter.pipeline],
        filters: [%__MODULE__{context: filter.context, pattern: pattern} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{}) do
    {[
       quote do
         defp unquote("pattern")(string, path) do
           unless Regex.match?(sigil_r(<<unquote(filter.pattern)>>, []), string) do
             Exonerate.mismatch(string, path)
           end

           string
         end
       end
     ], []}
  end
end
