defmodule Exonerate do

  @type json ::
     %{optional(String.t) => json}
     | list(json)
     | String.t
     | number
     | boolean
     | nil

  @type mismatch :: {:mismatch, {module, atom, [json]}}

  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Annotate
  alias Exonerate.BuildCond
  alias Exonerate.Parser

  @type specmap  :: %{optional(String.t) => json}
  @type condlist :: [BuildCond.condclause]
  @type ast_def :: {:defp, any, any} | {:def, any, any}
  @type ast_blk :: {:__block__, any, any}
  @type ast_tag :: {:@, any, any}
  @type defblock :: ast_def | ast_blk | ast_tag
  @type public :: {:public, atom}
  @type refreq :: {:refreq, atom}
  @type refimp :: {:refimp, atom}
  @type annotated_ast :: defblock | public | refreq | refimp

  defmacro defschema([{method, json} | _opts]) do
    spec = json
    |> maybe_desigil
    |> Jason.decode!

    final_ast = spec
    |> Parser.new_match(method)
    |> Parser.collapse_deps
    |> Parser.external_deps(spec)
    |> Annotate.public
    |> Parser.defp_to_def

    res = quote do
      unquote_splicing(final_ast)
    end

    #res |> Macro.to_string |> IO.puts

    res
  end

  ##############################################################################
  ## utilities

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(any), do: any

  @spec mismatch(module, atom, any) :: {:mismatch, {module, atom, [any]}}
  def mismatch(m, f, a) do
    {:mismatch, {m, f, [a]}}
  end

end
