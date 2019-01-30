defmodule Exonerate.Annotate do

  @type public_t::Exonerate.public

  @spec public(atom)::public_t
  def public(atom), do: {:public, atom}
end
