defmodule Exonerate.Tools do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Type

  # GENERAL-USE MACROS
  defmacro mismatch(error_value, schema_pointer, json_pointer, opts \\ [])

  defmacro mismatch(error_value, {schema_pointer, extras}, json_pointer, opts) do
    primary = Keyword.take(binding(), ~w(error_value json_pointer)a)
    schema_pointer = JsonPointer.to_path(schema_pointer)

    schema_pointer = [
      schema_pointer:
        quote do
          Path.join(unquote(schema_pointer), unquote(extras))
        end
    ]

    extras = Keyword.take(opts, ~w(reason failures matches required)a)

    quote bind_quoted: [error_params: primary ++ schema_pointer ++ extras] do
      {:error, error_params}
    end
  end

  defmacro mismatch(error_value, schema_pointer, json_pointer, opts) do
    primary = Keyword.take(binding(), ~w(error_value json_pointer)a)
    schema_pointer = [schema_pointer: JsonPointer.to_path(schema_pointer)]
    extras = Keyword.take(opts, ~w(reason failures matches required)a)

    quote bind_quoted: [error_params: primary ++ schema_pointer ++ extras] do
      {:error, error_params}
    end
  end

  # MACRO TOOLS
  def inspect(macro, filter \\ true) do
    if filter do
      macro
      |> scrub_macros
      |> Macro.to_string()
      |> IO.puts()
    end

    macro
  end

  # this macro exists to trap error outputs (in case and with matching blocks)
  # as the pattern `error = {:error, _}` in test environment for safety, but to
  # elide that into the single `error` variable in other environments for
  # performance

  if Mix.env() === :test do
    defmacro error_match(error) do
      quote do
        unquote(error) = {:error, _}
      end
    end
  else
    defmacro error_match(error), do: error
  end

  # scrub macros helps to make "dump: true" output more legible, by removing
  # the scar tissue of macro calls that are going to be dumped anyways.

  @drop_macros ~w(filter accessories fallthrough iterator)a

  defp scrub_macros({:__block__, meta, content}) do
    {:__block__, meta, scrub_macros(content)}
  end

  defp scrub_macros(content) when is_list(content) do
    Enum.flat_map(content, &List.wrap(scrub_macros(&1)))
  end

  defp scrub_macros({:require, _, _}), do: []

  defp scrub_macros({{:., _, [_module, call]}, _, _}) when call in @drop_macros, do: []

  defp scrub_macros(other), do: other

  def maybe_dump(macro, opts) do
    __MODULE__.inspect(macro, Keyword.get(opts, :dump))
  end

  # SUBSCHEMA MANIPULATION

  @spec subschema(Macro.Env.t(), atom, JsonPointer.t()) :: Type.json()
  def subschema(caller, authority, pointer) do
    caller.module
    |> Cache.fetch_schema!(authority)
    |> JsonPointer.resolve_json!(pointer)
  end

  @spec parent(Macro.Env.t(), atom, JsonPointer.t()) :: Type.json()
  def parent(caller, authority, pointer) do
    caller.module
    |> Cache.fetch_schema!(authority)
    |> JsonPointer.resolve_json!(JsonPointer.backtrack!(pointer))
  end

  @spec call(atom, JsonPointer.t(), Keyword.t()) :: atom
  def call(authority, pointer, opts) do
    pointer
    |> if(Keyword.get(opts, :tracked, false), &JsonPointer.join(&1, ":tracked"))
    |> JsonPointer.to_uri()
    |> struct(path: "#{authority}")
    |> to_string
    |> adjust_length
    |> String.to_atom()
  end

  # a general strategy to adjust the length of a string that needs to become an atom,
  # works when the string's length is too big.  Assumes that the string is UTF-8 encoded.
  defp adjust_length(string) when byte_size(string) < 255, do: string

  defp adjust_length(string) do
    # take the first 25 and last 25 characters and put the base16-hashed value in the middle
    g = String.graphemes(string)
    first = Enum.take(g, 25)
    last = g |> Enum.reverse() |> Enum.take(25) |> Enum.reverse()
    middle = Base.encode16(<<:erlang.phash2(string)::32>>)
    IO.iodata_to_binary([first, "..", middle, "..", last])
  end

  # scans an entire jsonschema by reducing over it and returns certain things back.
  @spec scan(Type.json(), acc, (Type.json(), JsonPointer.t(), acc -> acc)) :: acc when acc: term
  def scan(object, acc, transformation) do
    do_scan(object, JsonPointer.from_path("/"), acc, transformation)
  end

  defp do_scan(object, pointer, acc, transformation) when is_map(object) do
    acc = transformation.(object, pointer, acc)

    Enum.reduce(object, acc, fn
      {k, v}, acc ->
        do_scan(v, JsonPointer.join(pointer, k), acc, transformation)
    end)
  end

  defp do_scan(array, pointer, acc, transformation) when is_list(array) do
    acc = transformation.(array, pointer, acc)

    array
    |> Enum.reduce({acc, 0}, fn
      v, {acc, index} ->
        {do_scan(v, JsonPointer.join(pointer, "#{index}"), acc, transformation), index + 1}
    end)
    |> elem(0)
  end

  defp do_scan(data, pointer, acc, transformation) do
    transformation.(data, pointer, acc)
  end

  # general tools
  @spec if(content, as_boolean(term), (content -> content)) :: content when content: term
  def if(content, as_boolean, predicate) do
    if as_boolean, do: predicate.(content), else: content
  end
end
