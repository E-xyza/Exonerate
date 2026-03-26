defmodule Exonerate.Tools do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Type

  # GENERAL-USE MACROS
  defmacro mismatch(error_value, resource, keyword_pointer, json_pointer, opts \\ [])

  defmacro mismatch(
             error_value,
             resource,
             {keyword_pointer, extras},
             instance_location,
             opts
           ) do
    primary = Keyword.take(binding(), ~w(error_value instance_location)a)
    uri = "#{resource_pointer_to_uri(resource, keyword_pointer, trim: true)}"

    absolute_keyword_location = [
      absolute_keyword_location:
        quote do
          Path.join(unquote(uri), unquote(extras))
        end
    ]

    extras = Keyword.take(opts, ~w(reason errors matches required)a)

    quote bind_quoted: [error_params: primary ++ absolute_keyword_location ++ extras] do
      {:error, error_params}
    end
  end

  defmacro mismatch(error_value, resource, keyword_pointer, instance_location, opts) do
    primary = Keyword.take(binding(), ~w(error_value instance_location)a)

    absolute_keyword_location = [
      absolute_keyword_location:
        "#{resource_pointer_to_uri(resource, keyword_pointer, trim: true)}"
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

  @drop_macros ~w(filter accessories fallthrough iterator context default_filter functions)a

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

  def maybe_dump(macro, env, opts) do
    macro
    |> evaluate_internal_macros(env)
    |> __MODULE__.inspect(Keyword.get(opts, :dump))
  end

  defp evaluate_internal_macros(macro, env) do
    macro
    |> Macro.prewalk([], &expand_some(&1, &2, env))
    |> elem(0)
  end

  @expanded_names ~w(initializer next_contains next_unique)a

  # some macros exist inside of the function bodies and we need to explicitly expand these
  # to make debugging possible.
  defp expand_some(macro = {{:., _, [_, name]}, _, _}, [], env) when name in @expanded_names do
    # a little bit of a bad thing to do, but this is a debug operation, so this will be
    # updated if needs be.
    augmented_env =
      quote do
        (fn ->
           require Exonerate.Combining
           require Exonerate.Filter.Contains
           require Exonerate.Filter.UniqueItems
           __ENV__
         end).()
      end
      |> Code.eval_quoted([], env)
      |> elem(0)

    {Macro.expand(macro, augmented_env), []}
  end

  defp expand_some(macro, [], _), do: {macro, []}

  # SUBSCHEMA MANIPULATION

  @spec subschema(Macro.Env.t(), String.t(), JsonPtr.t()) :: Type.json()
  def subschema(caller, resource, pointer) do
    caller.module
    |> Cache.fetch_schema!(resource)
    |> JsonPtr.resolve_json!(pointer)
  end

  @spec parent(Macro.Env.t(), String.t(), JsonPtr.t()) :: Type.json()
  def parent(caller, resource, pointer) do
    caller.module
    |> Cache.fetch_schema!(resource)
    |> JsonPtr.resolve_json!(JsonPtr.backtrack!(pointer))
  end

  @spec call(String.t(), JsonPtr.t(), Keyword.t()) :: atom
  @spec call(String.t(), JsonPtr.t(), atom, Keyword.t()) :: atom
  def call(resource, pointer, suffix \\ nil, opts) when is_binary(resource) do
    resource
    |> URI.parse()
    |> uri_merge(JsonPtr.to_uri(pointer))
    |> to_string
    |> append_suffix(suffix)
    |> append_tracked(opts[:tracked])
    |> adjust_length
    |> escape_debug_names(opts)
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

  defp escape_debug_names(name, opts) do
    if opts[:dump] do
      name
      |> String.replace(~r/exonerate:\/\/[A-F0-9]{64}/, "entrypoint")
      |> String.replace("#", "at")
      |> String.replace(~r/[-:\/]/, "_")
    else
      name
    end
  end

  # scans an entire jsonschema by reducing over it and returns certain things back.
  @spec scan(Type.json(), acc, (Type.json(), JsonPtr.t(), acc -> acc)) :: acc when acc: term
  def scan(object, acc, transformation) do
    do_scan(object, JsonPtr.from_path("/"), acc, transformation)
  end

  defp do_scan(object, pointer, acc, transformation) when is_map(object) do
    acc = transformation.(object, pointer, acc)

    Enum.reduce(object, acc, fn
      {k, v}, acc ->
        do_scan(v, JsonPtr.join(pointer, k), acc, transformation)
    end)
  end

  defp do_scan(array, pointer, acc, transformation) when is_list(array) do
    acc = transformation.(array, pointer, acc)

    array
    |> Enum.reduce({acc, 0}, fn
      v, {acc, index} ->
        {do_scan(v, JsonPtr.join(pointer, "#{index}"), acc, transformation), index + 1}
    end)
    |> elem(0)
  end

  defp do_scan(data, pointer, acc, transformation) do
    transformation.(data, pointer, acc)
  end

  # options tools

  def entrypoint(opts) do
    opts
    |> Keyword.get(:entrypoint, "/")
    |> JsonPtr.from_path()
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
    encoding = Keyword.fetch!(opts, :encoding)

    opts
    |> Keyword.fetch!(:decoders)
    |> List.keyfind(encoding, 0)
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

  @spec resource_pointer_to_uri(String.t(), JsonPtr.t(), keyword) :: URI.t()
  def resource_pointer_to_uri(resource, pointer, opts \\ []) do
    resource
    |> URI.parse()
    |> uri_merge(JsonPtr.to_uri(pointer))
    |> if(opts[:trim], fn
      uri = %{scheme: "file"} -> %URI{fragment: uri.fragment}
      uri = %{scheme: "exonerate"} -> %URI{fragment: uri.fragment}
      uri -> uri
    end)
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

        cond do
          String.starts_with?(dest_path, "/") ->
            %URI{
              path: dest_path,
              query: target.query,
              fragment: target.fragment
            }

          String.ends_with?(path, "/") ->
            %URI{
              path: Path.join(base_path, dest_path),
              query: target.query,
              fragment: target.fragment
            }

          true ->
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

  def encoding_from_extension(uri_or_path, opts) do
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
          {_, encoding} -> encoding
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
