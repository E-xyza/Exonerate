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
  alias Exonerate.MatchNumber
  alias Exonerate.MatchObject
  alias Exonerate.MatchString
  alias Exonerate.Metadata
  alias Exonerate.Method
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

    components = exschema
    |> matcher(method)
    # prepend a term stating that the generated method
    # is guaranteed to be public, and have the desired spec.
    |> fn arr -> [Annotate.public(method) | arr] end.()
    |> Enum.group_by(&discriminator/1)
    |> clear_requests
    |> process(exschema)
    |> defp_to_def

    res = quote do
      unquote_splicing(components)
    end

    #res
    #|> Macro.to_string
    #|> IO.puts

    res
  end

  def clear_requests(map) do
    unhandled_requests = if map[:refreq] do
      map[:refreq]
      |> Enum.uniq
      |> Enum.reject(fn {:refreq, v} ->
        map[:refimp] && ({:refimp, v} in map[:refimp])
      end)
    else
      []
    end
    Map.put(map, :refreq, unhandled_requests)
  end

  def process(m = %{refreq: []}, _), do: m
  def process(m = %{refreq: [{:refreq, head} | tail]}, exschema) do
    # navigate to the schema element referenced by the reference request
    subschema = Method.subschema(exschema, head)

    components = subschema
    |> matcher(head)
    |> Enum.group_by(&discriminator/1)

    new_m = %{
      refreq: tail ++ (components[:refreq] || []),
      refimp: m.refimp ++ (components[:refimp] || []),
      public: m.public ++ (components[:public] || []),
      blocks: m.blocks ++ (components[:blocks] || [])
    } |> clear_requests

    process(new_m, exschema)
  end

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec matcher(json, atom)::[annotated_ast]
  def matcher(true, method), do: always_matches(method)
  def matcher(false, method), do: never_matches(method)
  # metadata things
  def matcher(spec = %{"title" => title}, method),       do: Metadata.set_title(spec, title, method)
  def matcher(spec = %{"description" => desc}, method),  do: Metadata.set_description(spec, desc, method)
  def matcher(spec = %{"default" => default}, method),   do: Metadata.set_default(spec, default, method)
  def matcher(spec = %{"examples" => examples}, method), do: Metadata.set_examples(spec, examples, method)
  def matcher(spec = %{"$schema" => schema}, method),    do: Metadata.set_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method),            do: Metadata.set_id(spec, id, method)
  # match refs - refs override all other specs.
  def matcher(       %{"$ref" => ref}, method),          do: Reference.match(ref, method)
  # match if-then-else
  def matcher(spec = %{"if" => _}, method),              do: Conditional.match(spec, method)
  # match enums and consts
  def matcher(spec = %{"enum" => elist}, method),        do: MatchEnum.match_enum(spec, elist, method)
  def matcher(spec = %{"const" => const}, method),       do: MatchEnum.match_const(spec, const, method)
  # match combining elements
  def matcher(spec = %{"allOf" => clist}, method),       do: Combining.match_allof(spec, clist, method)
  def matcher(spec = %{"anyOf" => clist}, method),       do: Combining.match_anyof(spec, clist, method)
  def matcher(spec = %{"oneOf" => clist}, method),       do: Combining.match_oneof(spec, clist, method)
  def matcher(spec = %{"not" => inv}, method),           do: Combining.match_not(spec, inv, method)
  # type matching things
  def matcher(spec, method) when spec == %{},            do: always_matches(method)
  def matcher(spec = %{"type" => "boolean"}, method),    do: match_boolean(spec, method)
  def matcher(spec = %{"type" => "null"}, method),       do: match_null(spec, method)
  def matcher(spec = %{"type" => "string"}, method),     do: MatchString.match(spec, method)
  def matcher(spec = %{"type" => "integer"}, method),    do: MatchNumber.match_int(spec, method)
  def matcher(spec = %{"type" => "number"}, method),     do: MatchNumber.match(spec, method)
  def matcher(spec = %{"type" => "object"}, method),     do: MatchObject.match(spec, method)
  def matcher(spec = %{"type" => "array"}, method),      do: MatchArray.match(spec, method)
  # lists and no type spec
  def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)
  def matcher(spec, method), do: match_list(spec, @all_types, method)

  @spec always_matches(atom) :: [defblock]
  def always_matches(method) do
    [ Annotate.impl(method),
      quote do
        defp unquote(method)(_val) do
          :ok
        end
      end ]
  end

  @spec never_matches(atom) :: [defblock]
  def never_matches(method) do
    [ Annotate.impl(method),
      quote do
        defp unquote(method)(val) do
          Exonerate.mismatch(__MODULE__, unquote(method), val)
        end
      end ]
  end

  @spec match_boolean(map, atom, boolean) :: [defblock]
  defp match_boolean(_spec, method, terminal \\ true) do

    bool_match = quote do
      defp unquote(method)(val) when is_boolean(val) do
        :ok
      end
    end

    if terminal do
      [ Annotate.impl(method),
        bool_match
      | never_matches(method)]
    else
      [Annotate.impl(method), bool_match]
    end
  end

  @spec match_null(map, atom, boolean) :: [defblock]
  defp match_null(_spec, method, terminal \\ true) do

    null_match = quote do
      defp unquote(method)(val) when is_nil(val) do
        :ok
      end
    end

    if terminal do
      [ Annotate.impl(method),
        null_match
      | never_matches(method)]
    else
      [Annotate.impl(method), null_match]
    end
  end

  @spec match_list(map, list, atom) :: [defblock]
  defp match_list(_spec, [], method), do: never_matches(method)
  defp match_list(spec, ["string" | tail], method) do
    head_code = MatchString.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["integer" | tail], method) do
    head_code = MatchNumber.match_int(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["number" | tail], method) do
    head_code = MatchNumber.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["object" | tail], method) do
    head_code = MatchObject.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["array" | tail], method) do
    head_code = MatchArray.match(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["boolean" | tail], method) do
    head_code = match_boolean(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["null" | tail], method) do
    head_code = match_null(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end

  #############################################################################
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

  #
  # defp_to_def/1 --
  #
  # takes a map with an AST in `:blocks` and a list of methods to be shifted to
  # public in `:public`, then trampolines it to defp_to_def/2 for conversion of
  # the blocks into a block list as converted.
  #
  @spec defp_to_def(
    %{
      required(:blocks) => [defblock],
      required(:public) => [{:public, atom}],
      optional(atom) => any
     }
  )::[defblock]
  defp defp_to_def(map) when is_map(map) do
    public_list = Enum.map(map.public, fn
      {:public, token} -> token
    end)

    Enum.map(map.blocks, &defp_to_def(&1, public_list))
  end

  #
  # defp_to_def/2 --
  #
  # recursively goes through block statements, substitituting defp's
  # as needed (some might have `when` substatements).  Skips over other
  # types of elements, e.g. @ tags.
  #
  @spec defp_to_def(defblock, [atom])::defblock
  defp defp_to_def({:__block__, context, blocklist}, list) do
    {
      :__block__,
      context,
      Enum.map(blocklist, &defp_to_def(&1, list))
    }
  end
  defp defp_to_def({:defp, context, content = [{:when, _, [{title, _, _} | _]} | _]}, list) do
    defp_to_def(context, content, title, list)
  end
  defp defp_to_def({:defp, context, content = [{title, _, _} | _]}, list) do
    defp_to_def(context, content, title, list)
  end
  defp defp_to_def(any, _), do: any

  #
  # defp_to_def/4 --
  #
  # used as a trampoline by defp_to_def/2 -> presumably matched against a
  # defp statement and is given all the information needed to decide if the
  # statement needs to be substituted for a def, and does so if the 'title'
  # parameter is in the list of "to change to def".  Publicized methods are
  # given @spec statements.
  #
  @spec defp_to_def(any, any, atom, [atom])::defblock
  defp defp_to_def(context, content, title, list) do
    if title in list do
      defblock = {:def, context, content}
      quote do
        unquote(defblock)
      end
    else
      {:defp, context, content}
    end
  end

end
