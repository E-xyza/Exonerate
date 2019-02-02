defmodule Exonerate.Parser do

  @moduledoc """

  defines the `%Exonerate.Parser{}` struct type.

  this type holds the most important values which are used by
  the exonerate parser.  `blocks:` are `@spec`s, `defp`s, and
  `@doc`s.  `public:` is a MapSet of all `defp`s which are to be
  converted to `def`s at the end of the process.  `refreq:` is
  a MapSet of references that have been requested along the
  process of parsing, and `refimp:` is a MapSet of implementations
  that have been produced.

  """

  alias Exonerate.Annotate
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

  defstruct method: nil,
            blocks: [],
            public: MapSet.new([]),
            refreq: MapSet.new([]),
            refimp: MapSet.new([]),
            deps: []

  @type defp_ast  :: {:defp, list(any), list(any)}
  @type def_ast   :: {:def, list(any), list(any)}
  @type tag_ast   :: {:@, list(any), list(any)}
  @type block_ast :: {:__block__, list(any), list(ast)}
  @type ast :: defp_ast | def_ast | tag_ast | block_ast

  @type json :: Exonerate.json

  @type t :: %__MODULE__{
    method: atom,
    blocks: list(ast),
    public: MapSet.t(atom),
    refreq: MapSet.t(atom),
    refimp: MapSet.t(atom),
    deps: [t]
  }

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec root(atom)::t
  @doc """
  generates a parser struct which is poised to trigger the construction and
  building of the method root functions.
  """
  def root(method) do
    %__MODULE__{method: method, refreq: MapSet.new([method])}
  end

  @spec new_match(json, atom)::t
  def new_match(spec, method) do
    __MODULE__
    |> struct!
    |> Map.put(:method, method)
    |> match(spec)
  end

  @spec match(t, json)::t
  ## match non-objects
  def match(p, true), do: always_matches(p)
  def match(p, false), do: never_matches(p, true)
  ## match metadata
  def match(p, spec = %{"title" => title}),       do: Metadata.set_title(p, spec, title)
  def match(p, spec = %{"description" => desc}),  do: Metadata.set_description(p, spec, desc)
  def match(p, spec = %{"default" => default}),   do: Metadata.set_default(p, spec, default)
  def match(p, spec = %{"examples" => examples}), do: Metadata.set_examples(p, spec, examples)
  def match(p, spec = %{"$schema" => schema}),    do: Metadata.set_schema(p, spec, schema)
  def match(p, spec = %{"$id" => id}),            do: Metadata.set_id(p, spec, id)
  ## match refs - refs override all other specs.
  def match(p,        %{"$ref" => ref}),          do: Reference.match(p, ref)
  ## match if-then-else
  def match(p, spec = %{"if" => _}),              do: Conditional.match(p, spec)
  ## match enums and consts
  def match(p, spec = %{"enum" => elist}),        do: MatchEnum.match_enum(p, spec, elist)
  def match(p, spec = %{"const" => const}),       do: MatchEnum.match_const(p, spec, const)
  ## match combining elements
  def match(p, spec = %{"anyOf" => clist}),       do: Combining.match_anyof(p, spec, clist)
  def match(p, spec = %{"allOf" => clist}),       do: Combining.match_allof(p, spec, clist)
  def match(p, spec = %{"oneOf" => clist}),       do: Combining.match_oneof(p, spec, clist)
  def match(p, spec = %{"not" => inv}),           do: Combining.match_not(p, spec, inv)
  #type matching
  def match(p, spec) when spec == %{},            do: always_matches(p)
  def match(p, spec = %{"type" => "boolean"}),    do: match_boolean(p, spec)
  def match(p, spec = %{"type" => "null"}),       do: match_null(p, spec)
  def match(p, spec = %{"type" => "string"}),     do: MatchString.match(p, spec)
  def match(p, spec = %{"type" => "integer"}),    do: MatchNumber.match_int(p, spec)
  def match(p, spec = %{"type" => "number"}),     do: MatchNumber.match(p, spec)
  def match(p, spec = %{"type" => "object"}),     do: MatchObject.match(p, spec)
  def match(p, spec = %{"type" => "array"}),      do: MatchArray.match(p, spec)
  # lists and no type spec
  def match(p, spec = %{"type" => list}) when is_list(list), do: match_list(p, spec, list)
  def match(p, spec), do: match_list(p, spec, @all_types)

  @spec always_matches(t) :: t
  def always_matches(parser) do
    parser
    |> Annotate.impl
    |> append_block(
      quote do
        defp unquote(parser.method)(_val) do
          :ok
        end
      end)
  end

  @spec never_matches(t, boolean) :: t
  def never_matches(parser, true) do
    parser
    |> Annotate.impl
    |> append_block(
      quote do
        defp unquote(parser.method)(val) do
          Exonerate.mismatch(__MODULE__, unquote(parser.method), val)
        end
      end)
  end
  def never_matches(parser, false), do: parser

  @spec match_boolean(t, map, boolean) :: t
  defp match_boolean(parser, _spec, terminal \\ true) do
    parser
    |> Annotate.impl
    |> append_block(
      quote do
        defp unquote(parser.method)(val) when is_boolean(val) do
          :ok
        end
      end)
    |> never_matches(terminal)
  end

  @spec match_null(t, map, boolean) :: t
  defp match_null(parser, _spec, terminal \\ true) do
    parser
    |> Annotate.impl
    |> append_block(
      quote do
        defp unquote(parser.method)(val) when is_nil(val) do
          :ok
        end
      end)
    |> never_matches(terminal)
  end

  @spec match_list(t, json, [String.t]) :: t
  defp match_list(p, _spec, []), do: never_matches(p, true)
  defp match_list(parser, spec, ["string" | tail]) do
    parser
    |> MatchString.match(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["integer" | tail]) do
    parser
    |> MatchNumber.match_int(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["number" | tail]) do
    parser
    |> MatchNumber.match(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["object" | tail]) do
    parser
    |> MatchObject.match(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["array" | tail]) do
    parser
    |> MatchArray.match(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["boolean" | tail]) do
    parser
    |> match_boolean(spec, false)
    |> match_list(spec, tail)
  end
  defp match_list(parser, spec, ["null" | tail]) do
    parser
    |> match_null(spec, false)
    |> match_list(spec, tail)
  end

  @spec append_block(t, ast) :: t
  def append_block(parser, block) do
    %__MODULE__{parser | blocks: parser.blocks ++ [block]}
  end

  @spec add_dependencies(t, [t]) :: t
  def add_dependencies(parser, deps) when is_list(deps) do
    %__MODULE__{parser | deps: deps ++ parser.deps}
  end

  #
  # defp_to_def/1 --
  #
  # takes a struct then trampolines it to defp_to_def/2 for conversion of
  # the blocks into a block list as converted.
  #
  @spec defp_to_def(t)::[ast]
  def defp_to_def(parser) do
    public_specs(parser) ++ Enum.map(parser.blocks, &defp_to_def(&1, parser))
  end

  #
  # defp_to_def/2 --
  #
  # recursively goes through block statements, substitituting defp's
  # as needed (some might have `when` substatements).  Skips over other
  # types of elements, e.g. @ tags.
  #
  @spec defp_to_def(ast, t)::ast
  defp defp_to_def({:__block__, context, blocklist}, parser) do
    {
      :__block__,
      context,
      Enum.map(blocklist, &defp_to_def(&1, parser))
    }
  end
  defp defp_to_def({:defp, context, content = [{:when, _, [{title, _, _} | _]} | _]}, parser) do
    defp_to_def(context, content, title, parser)
  end
  defp defp_to_def({:defp, context, content = [{title, _, _} | _]}, parser) do
    defp_to_def(context, content, title, parser)
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
  @spec defp_to_def(any, any, atom, t)::ast
  defp defp_to_def(context, content, title, parser) do
    if title in parser.public do
      {:def, context, content}
    else
      {:defp, context, content}
    end
  end

  @spec collapse_deps(t) :: t
  def collapse_deps(p) do
    Enum.reduce(p.deps, p, &collapse_deps/2)
  end
  @spec collapse_deps(t, t) :: t
  defp collapse_deps(tgt, acc) do
    collapsed_tgt = collapse_deps(tgt)

    %__MODULE__{
      method: acc.method,
      blocks: acc.blocks ++ collapsed_tgt.blocks,
      public: MapSet.union(acc.public, collapsed_tgt.public),
      refreq: MapSet.union(acc.refreq, collapsed_tgt.refreq),
      refimp: MapSet.union(acc.refimp, collapsed_tgt.refimp),
      deps: Enum.reject(acc.deps, &(&1 == tgt))
    }
  end

  @emptyset MapSet.new([])

  @spec build_requested(t, json) :: t
  def build_requested(p = %__MODULE__{refreq: empty}, _spec)
    when empty == @emptyset, do: p
  def build_requested(p, spec) do
    p
    |> drop_satisfied_refs
    |> case do
      p = %__MODULE__{refreq: empty} when empty == @emptyset -> p
      p = %__MODULE__{refreq: refset} ->
        head = Enum.at(refset, 0)

        unbuilt_dep = spec
        |> Method.subschema(head)
        |> new_match(head)

        %{p | refreq: MapSet.delete(refset, head)}
        |> add_dependencies([unbuilt_dep])
        |> collapse_deps
        |> build_requested(spec)
    end
  end

  @spec drop_satisfied_refs(t) :: t
  def drop_satisfied_refs(p = %__MODULE__{refreq: refreq, refimp: refimp}) do
    %{p | refreq: Enum.reduce(refimp, refreq, &MapSet.delete(&2, &1))}
  end

  def public_specs(%__MODULE__{public: publics}) do
    Enum.map(publics, fn method ->
      quote do
        @spec unquote(method)(Exonerate.json):: :ok | Exonerate.mismatch
      end
    end)
  end

end
