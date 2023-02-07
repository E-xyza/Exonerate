defmodule Exonerate.Filter.ExclusiveMaximum do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  alias Exonerate.Context

  defstruct [:context, :maximum, :parent]

  # ignore version-4-type exclusiveMaximum specifiers.
  def parse(filter, %{"exclusiveMaximum" => bool}) when is_boolean(bool), do: filter

  def parse(filter = %type{}, %{"exclusiveMaximum" => maximum})
      when type in [Integer, Number] do
    %{
      filter
      | filters: [
          %__MODULE__{context: filter.context, maximum: maximum, parent: type}
          | filter.filters
        ]
    }
  end

  def compile(filter = %__MODULE__{parent: Integer}) do
    {[
       quote do
         defp unquote([])(integer, path)
              when is_integer(integer) and integer >= unquote(filter.maximum) do
           Exonerate.mismatch(integer, path, guard: "exclusiveMaximum")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{parent: Number}) do
    {[
       quote do
         defp unquote([])(number, path)
              when is_number(number) and number >= unquote(filter.maximum) do
           Exonerate.mismatch(number, path, guard: "exclusiveMaximum")
         end
       end
     ], []}
  end
end
