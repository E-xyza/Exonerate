defmodule Exonerate.Filter.MinProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :count]

  def parse(filter, %{"minProperties" => count}) do
    %{
      filter
      | filters: [%__MODULE__{context: filter.context, count: count} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[
       quote do
         defp unquote(fun(filter, []))(object, path)
              when is_map(object) and :erlang.map_size(object) < unquote(count) do
           Exonerate.mismatch(object, path, guard: unquote("minProperties"))
         end
       end
     ], []}
  end
end
