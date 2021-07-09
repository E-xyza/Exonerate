defmodule Exonerate.Type.Integer do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct [:pointer, :schema]
  @type t :: %__MODULE__{}

  def parse(_, _), do: %__MODULE__{}

  @spec compile(t) :: Macro.t
  def compile(_) do
    {quote do end, []}
  end
end
