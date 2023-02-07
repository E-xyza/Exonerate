defmodule Exonerate.Filter.ExclusiveMinimum do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :minimum, :parent]

  # ignore version-4-type exclusiveMaximum specifiers.
  def parse(filter, %{"exclusiveMinimum" => bool}) when is_boolean(bool), do: filter

  def parse(filter = %type{}, %{"exclusiveMinimum" => minimum})
      when type in [Integer, Number] do
    %{
      filter
      | filters: [
          %__MODULE__{context: filter.context, minimum: minimum, parent: type}
          | filter.filters
        ]
    }
  end

  def compile(filter = %__MODULE__{parent: Integer}) do
    {[
       quote do
         defp unquote(fun(filter, []))(integer, path)
              when is_integer(integer) and integer <= unquote(filter.minimum) do
           Exonerate.mismatch(integer, path, guard: "exclusiveMinimum")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{parent: Number}) do
    {[
       quote do
         defp unquote(fun(filter, []))(number, path)
              when is_number(number) and number <= unquote(filter.minimum) do
           Exonerate.mismatch(number, path, guard: "exclusiveMinimum")
         end
       end
     ], []}
  end
end
