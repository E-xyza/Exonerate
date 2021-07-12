defmodule Exonerate.Filter.Required do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :props]

  def parse(artifact, %{"required" => prop}) do
    %{artifact |
      filters: [%__MODULE__{context: artifact.context, props: prop} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{props: props}) do
    {props
    |> Enum.with_index()
    |> Enum.map(fn {prop, index} ->
      quote do
        defp unquote(fun(filter))(object, path) when is_map(object) and not is_map_key(object, unquote(prop)) do
          Exonerate.mismatch(object, path, guard: unquote("required/#{index}"))
        end
      end
    end), []}
  end

  defp fun(filter_or_artifact = %_{}) do
    Validator.to_fun(filter_or_artifact.context)
  end
end
