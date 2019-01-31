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
    exschema = json
    |> maybe_desigil
    |> Jason.decode!

    final_ast = exschema
    |> Parser.match(struct(Exonerate.Parser), method)
    |> Parser.collapse_deps
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


  # metadata things
  ## match refs - refs override all other specs.
  #def matcher(       %{"$ref" => ref}, method),          do: Reference.match(ref, method)
  ## match if-then-else
  #def matcher(spec = %{"if" => _}, method),              do: Conditional.match(spec, method)
  ## match enums and consts
  #def matcher(spec = %{"enum" => elist}, method),        do: MatchEnum.match_enum(spec, elist, method)
  #def matcher(spec = %{"const" => const}, method),       do: MatchEnum.match_const(spec, const, method)
  ## match combining elements
  #def matcher(spec = %{"allOf" => clist}, method),       do: Combining.match_allof(spec, clist, method)
  #def matcher(spec = %{"anyOf" => clist}, method),       do: Combining.match_anyof(spec, clist, method)
  #def matcher(spec = %{"oneOf" => clist}, method),       do: Combining.match_oneof(spec, clist, method)
  #def matcher(spec = %{"not" => inv}, method),           do: Combining.match_not(spec, inv, method)
  ## type matching things
  ## lists and no type spec
  #def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)
  #def matcher(spec, method), do: match_list(spec, @all_types, method)
#
  #@spec match_list(map, list, atom) :: [defblock]
  #defp match_list(_spec, [], method), do: never_matches(method)
  #defp match_list(spec, ["string" | tail], method) do
  #  head_code = MatchString.match(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["integer" | tail], method) do
  #  head_code = MatchNumber.match_int(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["number" | tail], method) do
  #  head_code = MatchNumber.match(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["object" | tail], method) do
  #  head_code = MatchObject.match(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["array" | tail], method) do
  #  head_code = MatchArray.match(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["boolean" | tail], method) do
  #  head_code = match_boolean(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
  #defp match_list(spec, ["null" | tail], method) do
  #  head_code = match_null(spec, method, false)
  #  tail_code = match_list(spec, tail, method)
  #  head_code ++ tail_code
  #end
#
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
