defmodule Exonerate.Method do
  @spec concat(atom, String.t) :: atom
  def concat(method, sub) do
    method
    |> Atom.to_string
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end
end
