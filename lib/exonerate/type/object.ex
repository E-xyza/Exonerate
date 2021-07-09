defmodule Exonerate.Type.Object do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct []
  @type t :: %__MODULE__{}

  def parse(_), do: %__MODULE__{}

  @spec compile(t, Validator.t) :: Macro.t
  def compile(_, _), do: :ok
end
