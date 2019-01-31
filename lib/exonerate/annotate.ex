defmodule Exonerate.Annotate do

  @type public_t :: Exonerate.public
  @type tag_t :: Exonerate.tag

  @spec spec(atom)::tag_t
  def spec(atom) do
    quote do
      @spec unquote(atom)(Exonerate.json):: :ok | Exonerate.mismatch
    end
  end

  @spec public(atom)::public_t
  def public(atom), do: {:public, atom}
end
