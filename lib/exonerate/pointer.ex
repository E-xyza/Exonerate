defmodule Exonerate.Pointer do
  # JSONPointer implementation.  Internally, it's managed as a
  # list of strings, with the head of the list being the outermost
  # leaf in the JSON structure, and the end of the list being the
  # root.

  @type t :: [String.t]
  alias Exonerate.Type

  @spec to_fun(path :: t, keyword) :: atom
  @doc """
  creates a function call for a specific JSONPointer.

  options:
  - context: prepends a context to the uri

  ```elixir
  iex> alias Exonerate.Pointer
  iex> Pointer.to_fun(["foo", "bar"])
  :"/bar/foo"
  iex> Pointer.to_fun(["foo~bar", "baz"])
  :"/baz/foo~0bar"
  iex> Pointer.to_fun(["€", "currency"])
  :"/currency/%E2%82%AC"
  iex> Pointer.to_uri([], context: "foo")
  :"foo/"
  ```
  """
  def to_fun(path, opts \\ []) do
    path
    |> to_uri(opts)
    |> String.to_atom
  end

  @spec from_uri(String.t) :: t
  @doc """
  converts a uri to a JSONPointer

  ```elixir
  iex> alias Exonerate.Pointer
  iex> Pointer.from_uri("/") # the root-only case
  []
  iex> Pointer.from_uri("/bar/foo")
  ["foo", "bar"]
  iex> Pointer.from_uri("/baz/foo~0bar")
  ["foo~bar", "baz"]
  iex> Pointer.from_uri("/currency/%E2%82%AC")
  ["€", "currency"]
  ```
  """
  def from_uri("/" <> rest) do
    rest
    |> URI.decode()
    |> String.split("/")
    |> Enum.map(&deescape/1)
    |> Enum.reverse
    |> case do
      [""] -> []
      pointer -> pointer
    end
  end

  @spec to_uri(t, keyword) :: String.t
  @doc """
  creates a JSONPointer to its URI equivalent.

  options
  - context: prepends a context to the uri.

  ```elixir
  iex> alias Exonerate.Pointer
  iex> Pointer.to_uri(["foo", "bar"])
  "/bar/foo"
  iex> Pointer.to_uri(["foo~bar", "baz"])
  "/baz/foo~0bar"
  iex> Pointer.to_uri(["€", "currency"])
  "/currency/%E2%82%AC"
  iex> Pointer.to_uri([], context: "foo")
  "foo#/"
  ```
  """
  def to_uri(path, opts \\ []) do
    str = path
    |> Enum.reverse
    |> Enum.map(&escape/1)
    |> Enum.map(&URI.encode/1)
    |> Enum.join("/")

    IO.iodata_to_binary([List.wrap(opts[:context]), "/", str])
  end

  @spec eval(pointer :: t, data :: Type.json) :: Type.json
  @doc """
  evaluates a JSONPointer given some json data

  ```elixir
  iex> alias Exonerate.Pointer
  iex> Pointer.eval([], true)
  true
  iex> Pointer.eval(["foo~bar"], %{"foo~bar" => "baz"})
  "baz"
  iex> Pointer.eval(["1", "€"], %{"€" => ["quux", "ren"]})
  "ren"
  ```
  """
  def eval([], data), do: data
  def eval([_ | _], data) when not (is_list(data) or is_map(data)) do
    raise ArgumentError, message: "#{Type.of data} can not take a path"
  end
  def eval(pointer, data) do
    pointer
    |> Enum.reverse
    |> eval_rev(data)
  end

  @spec eval_rev([String.t], Type.json) :: Type.json
  defp eval_rev([], data), do: data
  defp eval_rev([index | rest], data) when is_list(data) do
    eval_rev(rest, Enum.at(data, String.to_integer(index)))
  end
  defp eval_rev([key | rest], data) when is_map(data) do
    eval_rev(rest, Map.fetch!(data, key))
  end

  @spec deescape(String.t) :: String.t
  defp deescape(string) do
    string
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
  end

  @spec escape(String.t) :: String.t
  defp escape(string) do
    string
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end
end
