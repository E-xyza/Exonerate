defmodule Exonerate.Filter.MultipleOf do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :factor]

  def parse(filter = %type{}, %{"multipleOf" => factor})
      when is_integer(factor) and type in [Number, Integer] do
    %{
      filter
      | filters: [%__MODULE__{context: filter.context, factor: factor} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{}) do
    {[
       quote do
         defp unquote(fun(filter, []))(integer, path)
              when is_integer(integer) and rem(integer, unquote(filter.factor)) != 0 do
           Exonerate.mismatch(integer, path, guard: "multipleOf")
         end
       end
     ], []}
  end
end
