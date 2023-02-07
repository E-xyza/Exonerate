defmodule Exonerate.Filter.Required do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :props]

  def parse(filter, %{"required" => prop}) do
    %{
      filter
      | filters: [%__MODULE__{context: filter.context, props: prop} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{props: props}) do
    {props
     |> Enum.with_index()
     |> Enum.map(fn {prop, index} ->
       quote do
         defp unquote([])(object, path)
              when is_map(object) and not is_map_key(object, unquote(prop)) do
           required_path = Path.join(path, unquote(prop))

           Exonerate.mismatch(object, path,
             guard: unquote("required/#{index}"),
             required: required_path
           )
         end
       end
     end), []}
  end
end
