defmodule Exonerate.BuildCond do
  @moduledoc false

  @type expr :: {atom, list, any} | atom
  @type condclause :: {test::expr, clause::expr}
  @type right_arrow_ast :: {:"->", list, list(expr | list(expr))}
  @type defblock :: {:def, any, any}
  @type condblock :: :ok | {:cond, any, any}

  @spec build([condclause]) :: condblock
  @doc """
    Takes a list of conditional clauses.  These are pairs {test, clause}
    which describe the two arrow parts of a cond statement.  These are then turned
    into a proper cond block.  Note that there are no "native" ways to do this
    in a quoted fashion.
  """
  def build([]), do: :ok
  def build(cond_clauses) when is_list(cond_clauses) do

    # wrap turning the cond clauses into a right arrow list AST, inside
    # the standard AST for a cond clause.  This has been empirically
    # determined by looking at the output of the following:
    #
    # quote do
    #   cond do
    #     x -> y
    #   end
    # end

    {:cond, [], [[do: right_arrow_list_from(cond_clauses)]]}
  end

  @spec right_arrow_list_from([condclause]) :: [right_arrow_ast]
  defp right_arrow_list_from(cond_clauses) do

    # the right arrow clauses inside of a cond block are simply a list of
    # right arrows.  In all of our conditional clause generation, we want
    # to trap a default :ok response.

    Enum.map(cond_clauses, &right_arrow/1)
    ++ [right_arrow({true, :ok})]
  end

  @spec right_arrow({expr, expr}) :: right_arrow_ast
  defp right_arrow({test, clause}) do

    # the AST of a typical right arrow clause is encoded here.  I suspect
    # that the "test" section needs to be wrapped in an array because in
    # the elixir you can have multiple passing statements encode into a
    # single result expression, but we won't be using that capability in
    # exonerate.

    {:"->", [], [[test], clause]}
  end

end
