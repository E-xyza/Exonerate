defmodule Exonerate.Filter.MinProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  
  import Validator, only: [fun: 2]

  defstruct [:context, :count]

  def parse(artifact, %{"minProperties" => count}) do
    %{artifact |
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[quote do
      defp unquote(fun(filter, "minProperties"))(object, path) when is_map(object) and :erlang.map_size(object) < unquote(count) do
        Exonerate.mismatch(object, path, guard: unquote("minProperties"))
      end
    end], []}
  end
end
