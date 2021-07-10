defmodule Exonerate.Type.Null do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Validator

  @impl true
  @spec parse(Validator.t, Type.json) :: t
  def parse(validator, _schema) do
    %__MODULE__{context: validator}
  end

  @impl true
  @spec compile(t) :: Macro.t
  def compile(artifact) do
    quote do
      defp unquote(Validator.to_fun(artifact.context))(null, path) when is_nil(null) do
        :ok
      end
    end
  end
end
