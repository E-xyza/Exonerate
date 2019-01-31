defmodule Exonerate.Annotate do

  @moduledoc """
  defines several annotations that are generated alongside the
  """

  @type public_t :: Exonerate.public
  @type tag_t :: Exonerate.tag
  @type req_t :: Exonerate.refreq
  @type impl_t :: Exonerate.refimp

  @spec spec(atom)::tag_t
  @doc """
  generates a spec tag for a function, will be emitted as AST.
  """
  def spec(atom) do
    quote do
      @spec unquote(atom)(Exonerate.json):: :ok | Exonerate.mismatch
    end
  end

  @spec public(atom)::public_t
  @doc """
  marks that a method needs to be changed from a `defp` method to a
  `def` method.  Used for the root method and any method that surfaces
  queryable metadata.
  """
  def public(atom), do: {:public, atom}

  @spec req(atom)::req_t
  def req(atom), do: {:refreq, atom}

  @spec impl(atom)::impl_t
  @doc """
  marks that a method has been implemented
  """
  def impl(atom), do: {:refimp, atom}
end
