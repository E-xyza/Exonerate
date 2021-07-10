defmodule Exonerate.Type.Number do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  alias Exonerate.Validator

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  @spec parse(Validator.t, Type.json) :: t
  def parse(validator, _schema) do
    %__MODULE__{context: validator}
  end

  @spec compile(t) :: Macro.t
  def compile(artifact) do
    quote do
      defp unquote(Validator.to_fun(artifact.context))(number, path) when is_number(number) do
        :ok
      end
    end
  end
end
