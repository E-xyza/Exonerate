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
  alias Exonerate.MatchNumber
  alias Exonerate.MatchObject
  alias Exonerate.MatchString
  alias Exonerate.Metadata

  defstruct blocks: [],
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
    blocks: list(ast),
    public: MapSet.t(atom),
    refreq: MapSet.t(atom),
    refimp: MapSet.t(atom),
    deps: list(t)
  }

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec match(json, t, atom)::t
  def match(true, p, method), do: always_matches(p, method)
  def match(false, p, method), do: never_matches(p, method)
  def match(spec = %{"title" => title}, p, method),       do: Metadata.set_title(spec, p, title, method)
  def match(spec = %{"description" => desc}, p, method),  do: Metadata.set_description(spec, p, desc, method)
  def match(spec = %{"default" => default}, p, method),   do: Metadata.set_default(spec, p, default, method)
  def match(spec = %{"examples" => examples}, p, method), do: Metadata.set_examples(spec, p, examples, method)
  def match(spec = %{"$schema" => schema}, p, method),    do: Metadata.set_schema(spec, p, schema, method)
  def match(spec = %{"$id" => id}, p, method),            do: Metadata.set_id(spec, p, id, method)

  #type matching
  def match(spec, p, method) when spec == %{},            do: always_matches(p, method)
  def match(spec = %{"type" => "boolean"}, p, method),    do: match_boolean(spec, p, method)
  def match(spec = %{"type" => "null"}, p, method),       do: match_null(spec, p, method)
  def match(spec = %{"type" => "string"}, p, method),     do: MatchString.match(spec, p, method)
  def match(spec = %{"type" => "integer"}, p, method),    do: MatchNumber.match_int(spec, p, method)
  def match(spec = %{"type" => "number"}, p, method),     do: MatchNumber.match(spec, p, method)
  def match(spec = %{"type" => "object"}, p, method),     do: MatchObject.match(spec, p, method)
  #def match(spec = %{"type" => "array"}, p, method),      do: MatchArray.match(spec, p, method)

  def match(_, p, method), do: never_matches(p, method)

  @spec always_matches(t, atom) :: t
  def always_matches(parser, method) do
    parser
    |> Annotate.impl(method)
    |> append_blocks(
      [quote do
        defp unquote(method)(_val) do
          :ok
        end
      end])
  end

  @spec never_matches(t, atom) :: t
  def never_matches(parser, method) do
    parser
    |> Annotate.impl(method)
    |> append_blocks(
      [quote do
        defp unquote(method)(val) do
          Exonerate.mismatch(__MODULE__, unquote(method), val)
        end
      end])
  end

  @spec match_boolean(map, t, atom, boolean) :: t
  defp match_boolean(_spec, parser!, method, terminal \\ true) do
    parser! = parser!
    |> Annotate.impl(method)
    |> append_blocks([quote do
        defp unquote(method)(val) when is_boolean(val) do
          :ok
        end
      end])

    if terminal do
      never_matches(parser!, method)
    else
      parser!
    end
  end

  @spec match_null(map, t, atom, boolean) :: t
  defp match_null(_spec, parser!, method, terminal \\ true) do
    parser! =  parser!
    |> Annotate.impl(method)
    |> append_blocks([quote do
        defp unquote(method)(val) when is_nil(val) do
          :ok
        end
      end])

    if terminal do
      never_matches(parser!, method)
    else
      parser!
    end
  end

  @spec append_blocks(t, [ast]) :: t
  def append_blocks(parser, blocks) do
    %{parser | blocks: parser.blocks ++ blocks}
  end

  @spec add_dependencies(t, [t]) :: t
  def add_dependencies(parser, deps) do
    %{parser | deps: parser.deps ++ deps}
  end

  #
  # defp_to_def/1 --
  #
  # takes a struct then trampolines it to defp_to_def/2 for conversion of
  # the blocks into a block list as converted.
  #
  @spec defp_to_def(t)::[ast]
  def defp_to_def(parser) do
    Enum.map(parser.blocks, &defp_to_def(&1, parser.public))
  end

  #
  # defp_to_def/2 --
  #
  # recursively goes through block statements, substitituting defp's
  # as needed (some might have `when` substatements).  Skips over other
  # types of elements, e.g. @ tags.
  #
  @spec defp_to_def(ast, MapSet.t(atom))::ast
  defp defp_to_def({:__block__, context, blocklist}, publics) do
    {
      :__block__,
      context,
      Enum.map(blocklist, &defp_to_def(&1, publics))
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
  @spec defp_to_def(any, any, atom, MapSet.t(atom))::ast
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

  @spec collapse_deps(t) :: t
  def collapse_deps(p) do
    Enum.reduce(p.deps, p, &collapse_deps/2)
  end
  @spec collapse_deps(t, t) :: t
  defp collapse_deps(tgt, acc) do
    collapsed_tgt = collapse_deps(tgt)

    %__MODULE__{
      blocks: acc.blocks ++ collapsed_tgt.blocks,
      public: MapSet.union(acc.public, collapsed_tgt.public),
      refreq: MapSet.union(acc.refreq, collapsed_tgt.refreq),
      refimp: MapSet.union(acc.refimp, collapsed_tgt.refimp),
      deps: Enum.reject(acc.deps, &(&1 == tgt))
    }
  end

end
