defmodule Exonerate.Tools do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Type

  # GENERAL-USE MACROS
  defmacro mismatch(error_value, absolute_keyword_location, json_pointer, opts \\ [])

  defmacro mismatch(error_value, {absolute_keyword_location, extras}, instance_location, opts) do
    primary = Keyword.take(binding(), ~w(error_value instance_location)a)
    absolute_keyword_location = JsonPointer.to_path(absolute_keyword_location)

    absolute_keyword_location = [
      absolute_keyword_location:
        quote do
          Path.join(unquote(absolute_keyword_location), unquote(extras))
        end
    ]

    extras = Keyword.take(opts, ~w(reason errors matches required)a)

    quote bind_quoted: [error_params: primary ++ absolute_keyword_location ++ extras] do
      {:error, error_params}
    end
  end

  defmacro mismatch(error_value, absolute_keyword_location, instance_location, opts) do
    primary = Keyword.take(binding(), ~w(error_value instance_location)a)

    absolute_keyword_location = [
      absolute_keyword_location: JsonPointer.to_path(absolute_keyword_location)
    ]

    extras = Keyword.take(opts, ~w(reason errors matches required)a)

    quote bind_quoted: [error_params: primary ++ absolute_keyword_location ++ extras] do
      {:error, error_params}
    end
  end

  # MACRO TOOLS
  def inspect(macro, filter \\ true) do
    if filter do
      macro
      |> scrub_macros
      |> case do
        [] ->
          []

        code ->
          code
          |> Macro.to_string()
          |> IO.puts()
      end
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

  defp scrub_macros({:__block__, _meta, []}), do: []

  defp scrub_macros(nil), do: []

  defp scrub_macros({:__block__, meta, content}) do
    case scrub_macros(content) do
      [] ->
        []

      scrubbed ->
        {:__block__, meta, scrubbed}
    end
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

  @spec subschema(Macro.Env.t(), String.t(), JsonPointer.t()) :: Type.json()
  def subschema(caller, resource, pointer) do
    caller.module
    |> Cache.fetch_schema!(resource)
    |> JsonPointer.resolve_json!(pointer)
  end

  @spec parent(Macro.Env.t(), String.t(), JsonPointer.t()) :: Type.json()
  def parent(caller, resource, pointer) do
    caller.module
    |> Cache.fetch_schema!(resource)
    |> JsonPointer.resolve_json!(JsonPointer.backtrack!(pointer))
  end

  @spec call(String.t(), JsonPointer.t(), Keyword.t()) :: atom
  @spec call(String.t(), JsonPointer.t(), atom, Keyword.t()) :: atom
  def call(resource, pointer, suffix \\ nil, opts) when is_binary(resource) do
    resource
    |> URI.parse()
    |> uri_merge(JsonPointer.to_uri(pointer))
    |> to_string
    |> append_suffix(suffix)
    |> append_tracked(opts[:tracked])
    |> adjust_length
    |> String.to_atom()
  end

  defp append_suffix(path, nil), do: path
  defp append_suffix(path, suffix), do: Path.join(path, ":" <> Atom.to_string(suffix))

  defp append_tracked(path, :object), do: Path.join(path, ":tracked_object")
  defp append_tracked(path, :array), do: Path.join(path, ":tracked_array")
  defp append_tracked(path, nil), do: path

  # a general strategy to adjust the length of a string that needs to become an atom,
  # works when the string's length is too big.  Assumes that the string is UTF-8 encoded.
  defp adjust_length(string) when byte_size(string) < 255, do: string

  defp adjust_length(string) do
    # take the first 10 and last 50 graphemes and put the base16-hashed value in the middle
    # it is not possible that this will still be too long, even if someone goes nuts with
    # UTF8-encoded content. (10 * 4) + 12 + 50 * 4 < 255.
    g = String.graphemes(string)
    first = Enum.take(g, 25)
    last = g |> Enum.reverse() |> Enum.take(50) |> Enum.reverse()
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

  # options tools

  @doc """
  scrubs an options keyword prior to entry into a non-combining context.  The following
  keywords should be scrubbed:

  - :only
  - :tracked
  - :seen
  """
  def scrub(opts) do
    Keyword.drop(opts, ~w(only tracked seen)a)
  end

  def entrypoint(opts) do
    opts
    |> Keyword.get(:entrypoint, "/")
    |> JsonPointer.from_path()
  end

  def set_decoders(opts) do
    opts
    |> Keyword.put_new(:decoders, [])
    |> Keyword.update!(:decoders, fn decoders ->
      decoders
      |> if(&(!List.keymember?(&1, "application/json", 0)), &[{"application/json", Jason} | &1])
      |> if(
        &(!List.keymember?(&1, "application/yaml", 0)),
        &[{"application/yaml", YamlElixir} | &1]
      )
    end)
  end

  def decode!(string, opts) do
    content_type = Keyword.fetch!(opts, :content_type)

    opts
    |> Keyword.fetch!(:decoders)
    |> List.keyfind(content_type, 0)
    |> case do
      {_, Jason} ->
        Jason.decode!(string)

      {_, YamlElixir} ->
        YamlElixir.read_from_string!(string)

      {_, {module, function}} ->
        apply(module, function, [string])
    end
  end

  # URI tools
  @spec uri_to_resource(URI.t()) :: String.t()
  def uri_to_resource(uri) do
    to_string(%{uri | fragment: nil})
  end

  @spec uri_merge(URI.t(), URI.t()) :: URI.t()
  @doc """
  extends the standard library URI.merge to also be able to merge a relative URI
  """
  def uri_merge(%{scheme: nil, userinfo: nil, host: nil, port: nil, path: path}, target) do
    case target do
      # target is relative.
      %{scheme: nil, userinfo: nil, host: nil, port: nil} ->
        base_path = path || "/"
        dest_path = target.path || ""

        if String.ends_with?(path, "/") do
          %URI{
            path: Path.join(base_path, dest_path),
            query: target.query,
            fragment: target.fragment
          }
        else
          %URI{
            path: Path.join(Path.dirname(base_path), dest_path),
            query: target.query,
            fragment: target.fragment
          }
        end

      # target is absolute.
      _ ->
        target
    end
  end

  def uri_merge(base, rel) do
    URI.merge(base, rel)
  end

  def content_type_from_extension(uri_or_path, opts) do
    case Path.extname("#{uri_or_path}") do
      ".json" ->
        "application/json"

      ".yaml" ->
        "application/yaml"

      other ->
        opts
        |> Keyword.get(:mimetype_mapping, [])
        |> List.keyfind(other, 0)
        |> case do
          {_, content_type} -> content_type
          nil -> "application/json"
        end
    end
  end

  # general tools
  @spec if(content, as_boolean(term) | (content -> boolean), (content -> content)) :: content
        when content: term
  def if(content, function, predicate) when is_function(function, 1) do
    if function.(content), do: predicate.(content), else: content
  end

  def if(content, as_boolean, predicate) do
    if as_boolean, do: predicate.(content), else: content
  end
end
