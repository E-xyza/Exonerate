defmodule Exonerate.Tools do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Type

  # GENERAL-USE MACROS
  defmacro mismatch(error_value, schema_pointer, json_pointer, opts \\ []) do
    primary = Keyword.take(binding(), ~w(error_value schema_pointer json_pointer)a)
    extras = Keyword.take(opts, ~w(reason failures matches required)a)

    quote bind_quoted: [error_params: primary ++ extras] do
      {:error, error_params}
    end
  end

  # MACRO TOOLS
  def inspect(macro, filter \\ true) do
    if filter do
      macro
      |> Macro.to_string()
      |> IO.puts()
    end

    macro
  end

  def maybe_dump(macro, opts) do
    __MODULE__.inspect(macro, Keyword.get(opts, :dump))
  end

  # SUBSCHEMA MANIPULATION

  @spec subschema(Macro.Env.t(), atom, JsonPointer.t(), context? :: boolean) :: Type.json()
  def subschema(caller, authority, pointer, context? \\ false) do
    caller.module
    |> Cache.fetch!(authority)
    |> JsonPointer.resolve!(pointer)
    |> if(context?, &Degeneracy.canonicalize/1)
  end


  @spec parent(Macro.Env.t(), atom, JsonPointer.t(), context? :: boolean) :: Type.json()
  def parent(caller, authority, pointer, context? \\ false) do
    caller.module
    |> Cache.fetch!(authority)
    |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
    |> if(context?, &Degeneracy.canonicalize/1)
  end

  @spec call(atom, JsonPointer.t(), Keyword.t) :: atom
  def call(authority, pointer, opts) do
    pointer
    |> if(tracked?(opts), &JsonPointer.join(&1, ":tracked"))
    |> JsonPointer.to_uri(authority: authority)
    |> adjust_length
    |> String.to_atom()
  end

  defp tracked?(opts) do
    opts[:track_items] || opts[:track_properties]
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

  # general tools
  @spec if(content, as_boolean(term), (content -> content)) :: content when content: term
  def if(content, as_boolean, predicate) do
    if as_boolean, do: predicate.(content), else: content
  end
end
