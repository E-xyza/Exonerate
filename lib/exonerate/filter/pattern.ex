defmodule Exonerate.Filter.Pattern do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :pattern]

  def parse(filter = %Exonerate.Type.String{}, %{"pattern" => pattern}) do
    %{
      filter
      | pipeline: [fun(filter, "pattern") | filter.pipeline],
        filters: [%__MODULE__{context: filter.context, pattern: pattern} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{}) do
    {[
       quote do
         defp unquote(fun(filter, "pattern"))(string, path) do
           unless Regex.match?(sigil_r(<<unquote(filter.pattern)>>, []), string) do
             Exonerate.mismatch(string, path)
           end

           string
         end
       end
     ], []}
  end
end
