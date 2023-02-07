defmodule Exonerate.Filter.MaxLength do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  defstruct [:context, :length, :format_binary]

  def parse(filter, %{"maxLength" => length}) do
    pipeline = List.wrap(unless filter.format_binary, do: "maxLength")

    %{
      filter
      | pipeline: pipeline ++ filter.pipeline,
        filters: [
          %__MODULE__{
            context: filter.context,
            length: length,
            format_binary: filter.format_binary
          }
          | filter.filters
        ]
    }
  end

  def compile(filter = %__MODULE__{format_binary: true}) do
    {[
       quote do
         defp unquote([])(string, path)
              when is_binary(string) and byte_size(string) > unquote(filter.length) do
           Exonerate.mismatch(string, path, guard: "maxLength")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{}) do
    {[],
     [
       quote do
         defp unquote("maxLength")(string, path) do
           if String.length(string) > unquote(filter.length) do
             Exonerate.mismatch(string, path)
           end

           string
         end
       end
     ]}
  end
end
