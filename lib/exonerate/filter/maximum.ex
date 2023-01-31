defmodule Exonerate.Filter.Maximum do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter.ExclusiveMaximum
  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :maximum, :parent]

  # for draft-4, punt to ExclusiveMaximum if "exclusiveMaximum" is specified.
  def parse(artifact = %type{}, %{"maximum" => maximum, "exclusiveMaximum" => true})
      when type in [Integer, Number] do
    %{
      artifact
      | filters: [
          %ExclusiveMaximum{context: artifact.context, maximum: maximum, parent: type}
          | artifact.filters
        ]
    }
  end

  def parse(artifact = %type{}, %{"maximum" => maximum}) when type in [Integer, Number] do
    %{
      artifact
      | filters: [
          %__MODULE__{context: artifact.context, maximum: maximum, parent: type}
          | artifact.filters
        ]
    }
  end

  def compile(filter = %__MODULE__{parent: Integer}) do
    {[
       quote do
         defp unquote(fun(filter, []))(integer, path)
              when is_integer(integer) and integer > unquote(filter.maximum) do
           Exonerate.mismatch(integer, path, guard: "maximum")
         end
       end
     ], []}
  end

  def compile(filter = %__MODULE__{parent: Number}) do
    {[
       quote do
         defp unquote(fun(filter, []))(number, path)
              when is_number(number) and number > unquote(filter.maximum) do
           Exonerate.mismatch(number, path, guard: "maximum")
         end
       end
     ], []}
  end
end
