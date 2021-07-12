defmodule Exonerate.Filter.MultipleOf do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  alias Exonerate.Type.Integer
  alias Exonerate.Type.Number
  defstruct [:context, :factor]

  def parse(artifact = %type{}, %{"multipleOf" => factor}) when is_integer(factor) and type in [Number, Integer]do
    %{artifact | filters: [%__MODULE__{context: artifact.context, factor: factor} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{}) do
    {[quote do
      defp unquote(Validator.to_fun(filter.context))(integer, path)
        when is_integer(integer) and rem(integer, unquote(filter.factor)) != 0 do
          Exonerate.mismatch(integer, path, guard: "multipleOf")
      end
    end], []}
  end
end
