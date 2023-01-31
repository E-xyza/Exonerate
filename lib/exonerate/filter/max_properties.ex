defmodule Exonerate.Filter.MaxProperties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :count]

  def parse(artifact, %{"maxProperties" => count}) do
    %{
      artifact
      | filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]
    }
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[
       quote do
         defp unquote(fun(filter, []))(object, path)
              when is_map(object) and :erlang.map_size(object) > unquote(count) do
           Exonerate.mismatch(object, path, guard: unquote("maxProperties"))
         end
       end
     ], []}
  end
end
