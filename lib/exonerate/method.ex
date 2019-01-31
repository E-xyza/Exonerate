defmodule Exonerate.Method do

  @moduledoc false

  import Logger

  @spec concat(atom, String.t) :: atom
  @doc """
  a generalized method that concatenates an atom with the
  next string in the method to generate a methodname.  Should
  strip certain suffixes (_base, any_of_base, etc).

  iex> Exonerate.Method.concat(:hello, "world")
  :hello__world

  iex> Exonerate.Method.concat(:hello___base, "world")
  :hello__world

  iex> Exonerate.Method.concat(:hello__any_of_base, "world")
  :hello__world
  """
  def concat(method, sub) do
    method
    |> Atom.to_string
    |> strip_base
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end

  defp strip_base(string) do
    Regex.replace(~r/^(.*)__(_|any_of_|all_of_|one_of_|not_)base$/, string, "\\1")
  end

  @spec to_lambda(atom) :: {:&, list, list}
  @doc """
  takes a method atom and converts it to a 1-arity lambda for a private
  function in the same module.
  """
  def to_lambda(method) do
    lambda = {method, [], :__MODULE__}
    quote do
      &unquote(lambda)/1
    end
  end

  @doc """
  a generalized method that finds the root method for the
  concatenated method.

  iex> Exonerate.Method.root(:hello)
  :hello

  iex> Exonerate.Method.root(:hello___base)
  :hello

  iex> Exonerate.Method.root(:hello__properties__foo)
  :hello
  """
  @spec root(atom)::atom
  def root(method) do
    method
    |> Atom.to_string
    |> String.split("__")
    |> List.first
    |> String.to_atom
  end

  @doc """
  a generalized method that translates jsonpaths into method
  names

  iex> Exonerate.Method.jsonpath_to_method(:hello, "#")
  :hello

  iex> Exonerate.Method.jsonpath_to_method(:hello, "#/foo")
  :hello__foo

  iex> Exonerate.Method.jsonpath_to_method(:hello, "#/foo/bar")
  :hello__foo__bar
  """
  @spec jsonpath_to_method(atom, String.t) :: atom
  def jsonpath_to_method(root, "#"), do: root
  def jsonpath_to_method(root, "#/" <> jsonpath) do
    jsonpath
    |> String.split("/")
    |> Enum.reduce(root, &concat(&2, &1))
  end
  def jsonpath_to_method(root, jsonpath) do
    Logger.error("#{jsonpath} path not currently supported")
    root
  end

  @spec subschema(Exonerate.json, atom | [String.t]) :: Exonerate.json
  @doc """
  traverses a method path to find the corresponding schema.

  iex> Exonerate.Method.subschema(%{"foo" => 1}, :hello__foo)
  1

  iex> Exonerate.Method.subschema(%{"foo" => %{"bar" => 1}}, :hello__foo__bar)
  1
  """
  def subschema(exschema, method) when is_atom(method) do
    [_ | path] = method
    |> Atom.to_string
    |> String.split("__")

    subschema(exschema, path)
  end
  def subschema(exschema, []), do: exschema
  def subschema(exschema, [head | tail]) do
    esc_head = escape_jsonp(head)
    if Map.has_key?(exschema, esc_head) do
      exschema
      |> Map.get(esc_head)
      |> subschema(tail)
    else
      raise "element #{esc_head} not found in schema #{Jason.encode!(exschema)}"
    end
  end

  @doc """
  escapes characters according to the jsonp standard.

  iex> Exonerate.Method.escape_jsonp("a~0b")
  "a~b"

  iex> Exonerate.Method.escape_jsonp("a%25b")
  "a%b"

  iex> Exonerate.Method.escape_jsonp("a~1b%25c")
  "a/b%c"

  iex> Exonerate.Method.escape_jsonp("a%g")
  "a%g"

  iex> Exonerate.Method.escape_jsonp("null control")
  "null control"
  """
  @spec escape_jsonp(String.t) :: String.t
  def escape_jsonp(str) do
    cond do
      # tilde one becomes slash.
      c = Regex.named_captures(~r/^(?<head>.*)\~1(?<tail>.*)$/, str)
        -> c["head"] <> "/" <> escape_jsonp(c["tail"])
      # tilde zero becomes tilde.
      c = Regex.named_captures(~r/^(?<head>.*)\~0(?<tail>.*)$/, str)
        -> c["head"] <> "~" <> escape_jsonp(c["tail"])
      # percent number becomes a unicode codepoint.
      c = Regex.named_captures(~r/^(?<head>.*)\%(?<val>[0-9A-F]+)(?<tail>.*)$/, str)
        -> c["head"] <>
           #hoo boy just live with this one:
           (List.to_string([String.to_integer(c["val"], 16)])) <>
           escape_jsonp(c["tail"])
      true ->
        str
    end
  end

end
