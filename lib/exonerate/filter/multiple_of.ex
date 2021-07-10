defmodule Exonerate.Filter.MultipleOf do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :factor]

  def parse(artifact = %Exonerate.Type.Integer{}, %{"multipleOf" => factor}) do
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
