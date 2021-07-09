defmodule Exonerate.Type.Null do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct []
  @type t :: %__MODULE__{}

  def parse(_), do: %__MODULE__{}

  def compile(_), do: :ok
end
