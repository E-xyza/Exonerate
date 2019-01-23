defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Macro.BuildCond
  alias Exonerate.Macro.Combining
  alias Exonerate.Macro.MatchArray
  alias Exonerate.Macro.MatchEnum
  alias Exonerate.Macro.MatchNumber
  alias Exonerate.Macro.MatchObject
  alias Exonerate.Macro.MatchString
  alias Exonerate.Macro.Metadata

  @type json     :: Exonerate.json
  @type specmap  :: %{optional(String.t) => json}
  @type condlist :: [BuildCond.condclause]
  @type defblock :: {:def, any, any}

  defmacro defschema([{method, json} | _opts]) do

    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    quote do
      unquote_splicing(code)
    end
  end

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec matcher(json, atom)::[defblock | {:__block__, any, any}]
  def matcher(true, method), do: always_matches(method)
  def matcher(false, method), do: never_matches(method)
  # metadata things
  def matcher(spec = %{"title" => title}, method),       do: Metadata.set_title(spec, title, method)
  def matcher(spec = %{"description" => desc}, method),  do: Metadata.set_description(spec, desc, method)
  def matcher(spec = %{"default" => default}, method),   do: Metadata.set_default(spec, default, method)
  def matcher(spec = %{"examples" => examples}, method), do: Metadata.set_examples(spec, examples, method)
  def matcher(spec = %{"$schema" => schema}, method),    do: Metadata.set_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method),            do: Metadata.set_id(spec, id, method)
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
    [quote do
      def unquote(method)(_val) do
        :ok
      end
    end]
  end

  @spec never_matches(atom) :: [defblock]
  def never_matches(method) do
    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
      end
    end]
  end

  @spec match_boolean(map, atom, boolean) :: [defblock]
  defp match_boolean(_spec, method, terminal \\ true) do

    bool_match = quote do
      def unquote(method)(val) when is_boolean(val) do
        :ok
      end
    end

    if terminal do
      [bool_match | never_matches(method)]
    else
      [bool_match]
    end
  end

  @spec match_null(map, atom, boolean) :: [defblock]
  defp match_null(_spec, method, terminal \\ true) do

    null_match = quote do
      def unquote(method)(val) when is_nil(val) do
        :ok
      end
    end

    if terminal do
      [null_match | never_matches(method)]
    else
      [null_match]
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

end
