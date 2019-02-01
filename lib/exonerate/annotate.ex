defmodule Exonerate.Annotate do

  @moduledoc """
  manages the annotations which are part of the parser
  """

  alias Exonerate.Parser

  @type tag_t :: Exonerate.tag

  @spec spec(atom)::tag_t
  @doc """
  generates a spec tag for a function, will be emitted as AST.
  """
  def spec(atom) do
    quote do
      @spec unquote(atom)(Exonerate.json):: :ok | Exonerate.mismatch
    end
  end

  @spec public(Parser.t)::Parser.t
  @doc """
  marks that a method needs to be changed from a `defp` method to a
  `def` method.  Used for the root method and any method that surfaces
  queryable metadata.
  """
  def public(parser) do
    %{parser | public: MapSet.put(parser.public, parser.method)}
  end

  @spec req(Parser.t, atom)::Parser.t
  def req(parser, method) do
    %{parser | refreq: MapSet.put(parser.refreq, method)}
  end

  @spec impl(Parser.t)::Parser.t
  @doc """
  marks that a method has been implemented
  """
  def impl(parser) do
    %{parser | refimp: MapSet.put(parser.refimp, parser.method)}
  end
end
