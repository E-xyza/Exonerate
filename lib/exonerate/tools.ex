defmodule Exonerate.Tools do
  @moduledoc false

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

  ## ENUMERABLE TOOLS

  def collect(accumulator, enumerable, reducer) do
    Enum.reduce(enumerable, accumulator, &reducer.(&2, &1))
  end

  def flatten([]), do: []

  def flatten(list) when is_list(list) do
    if Enum.all?(list, &is_list/1) do
      flatten(Enum.flat_map(list, & &1))
    else
      list
    end
  end

  ## AST TOOLS

  def variable(v), do: {v, [], Elixir}

  def arrow(preimage, out) do
    {:->, [], [preimage, out]}
  end

  ### JsonPointer to function name
  @spec pointer_to_fun_name(JsonPointer.t(), keyword) :: atom
  def pointer_to_fun_name(pointer, opts) do
    pointer
    |> JsonPointer.to_uri(opts)
    |> adjust_length
    |> String.to_atom()
  end

  # a general strategy to adjust the length of a string that needs to become an atom,
  # works when the string's length is too big.  Assumes that the string is UTF-8 encoded.
  def adjust_length(string) when byte_size(string) < 255, do: string

  def adjust_length(string) do
    # take the first 25 and last 25 characters and put the base16-hashed value in the middle
    g = String.graphemes(string)
    first = Enum.take(g, 25)
    last = g |> Enum.reverse() |> Enum.take(25) |> Enum.reverse()
    middle = Base.encode16(<<:erlang.phash2(string)::32>>)
    IO.iodata_to_binary([first, "..", middle, "..", last])
  end
end
