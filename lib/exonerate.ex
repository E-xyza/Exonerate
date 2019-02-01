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
  alias Exonerate.Combining
  alias Exonerate.Conditional
  alias Exonerate.MatchArray
  alias Exonerate.MatchEnum
  alias Exonerate.MatchObject
  alias Exonerate.MatchString
  alias Exonerate.Method
  alias Exonerate.Parser
  alias Exonerate.Reference

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
    |> Parser.match(struct(Exonerate.Parser), method)
    |> Parser.collapse_deps
    |> Parser.external_deps(spec)
    |> Annotate.public(method)
    |> Parser.defp_to_def

    quote do
      unquote_splicing(final_ast)
    end
  end

  #def clear_requests(map) do
  #  unhandled_requests = if map[:refreq] do
  #    map[:refreq]
  #    |> Enum.uniq
  #    |> Enum.reject(fn {:refreq, v} ->
  #      map[:refimp] && ({:refimp, v} in map[:refimp])
  #    end)
  #  else
  #    []
  #  end
  #  Map.put(map, :refreq, unhandled_requests)
  #end

  #def process(m = %{refreq: []}, _), do: m
  #def process(m = %{refreq: [{:refreq, head} | tail]}, exschema) do
  #  # navigate to the schema element referenced by the reference request
  #  subschema = Method.subschema(exschema, head)
#
  #  components = subschema
  #  |> matcher(head)
  #  |> Enum.group_by(&discriminator/1)
#
  #  new_m = %{
  #    refreq: tail ++ (components[:refreq] || []),
  #    refimp: m.refimp ++ (components[:refimp] || []),
  #    public: m.public ++ (components[:public] || []),
  #    blocks: m.blocks ++ (components[:blocks] || [])
  #  } |> clear_requests
#
  #  process(new_m, exschema)
  #end

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

  defp discriminator({:__block__, _, _}), do: :blocks
  defp discriminator({:defp, _, _}), do: :blocks
  defp discriminator({:@, _, _}), do: :blocks
  defp discriminator({atom, _}) when is_atom(atom), do: atom

end
