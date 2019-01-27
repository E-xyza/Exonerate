defmodule Exonerate.Method do

  @moduledoc false

  @doc """
  a generalized method that concatenates an atom with the
  next string in the method to generate a methodname.  Should
  strip certain suffixes (_base, any_of_base, etc).

  iex> Exonerate.Method.concat(:hello, "world")
  :hello__world

  iex> Exonerate.Method.concat(:hello___base, "world")
  :hello__world

  iex> Exonerate.Method.concat(:hello__any_of_base, "world")
  :hello__world
  """

  @spec concat(atom, String.t) :: atom
  def concat(method, sub) do
    method
    |> Atom.to_string
    |> strip_base
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end

  defp strip_base(string) do
    Regex.replace(~r/^(.*)__(_|any_of_|all_of_|one_of_|not_)base$/, string, "\\1")
  end
end
