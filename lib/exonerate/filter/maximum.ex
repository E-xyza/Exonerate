defmodule Exonerate.Filter.Maximum do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  alias Exonerate.Validator
  defstruct [:context, :maximum, :parent]

  def parse(artifact = %type{}, %{"maximum" => maximum}) when type in [Integer, Number] do
    %{artifact |
      filters: [%__MODULE__{context: artifact.context, maximum: maximum, parent: type} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{parent: Integer}) do
    {[quote do
      defp unquote(Validator.to_fun(filter.context))(integer, path)
        when is_integer(integer) and integer > unquote(filter.maximum) do
          Exonerate.mismatch(integer, path, guard: "maximum")
      end
    end], []}
  end

  def compile(filter = %__MODULE__{parent: Number}) do
    {[quote do
      defp unquote(Validator.to_fun(filter.context))(number, path)
        when is_number(number) and number > unquote(filter.maximum) do
          Exonerate.mismatch(number, path, guard: "maximum")
      end
    end], []}
  end
end
