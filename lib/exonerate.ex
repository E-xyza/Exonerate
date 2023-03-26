defmodule Exonerate do
  @moduledoc """
  An opinionated JSONSchema compiler for elixir.

  Currently supports JSONSchema drafts 4, 6, 7, 2019, and 2020.  *except:*

  - integer filters do not match exact integer floating point values.
  - multipleOf is not supported for the number type (don't worry, it IS supported
    for integers).  This is because Elixir does not support a floating point
    remainder guard, and also because it is impossible for a floating point to
    guarantee sane results (e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
  - currently remoteref is not supported.

  For details, see:  http://json-schema.org

  Exonerate is automatically tested against the JSONSchema test suite.

  ## Usage

  Exonerate is 100% compile-time generated.  You should include Exonerate with
  the `runtime: false` option in `mix.exs`.

  ### In your module:

  ```
  defmodule MyModule do
    require Exonerate

    Exonerate.function_from_string(:def, :function_name, \"""
    {
      "type": "string"
    }
    \""")
  end
  ```

  The above module generates a function `MyModule.function_name/1` that takes an erlang JSON term
  (`string | number | array | map | bool | nil`) and validates it based on the the JSONschema.  If
  the term validates, it produces `:ok`.  If the term fails to validate, it produces
  `{:error, keyword}`, where the key `:json_pointer` and points to the error location in the passed
  parameter, the `:schema_pointers` points to the validation that failed, and `error_value` is the
  failing inner term.

  ## Metadata

  The following metadata are accessible for the entrypoint in the jsonschema, by passing the corresponding
  atom.  Note this is only activated for `def` functions, and will not be available
  for `defp` functions.

  | JSONschema tag | atom parameter |
  |----------------|----------------|
  | $id            | `:id`          |
  | $schema        | `:schema`      |
  | default        | `:default`     |
  | examples       | `:examples`    |
  | description    | `:description` |
  | title          | `:title`       |

  ## Options

  The following options are available:

  - `:format`: a map of JSONpointers to tags with corresponding
    `{"format" => "..."}` filters.

    Exonerate ships with filters for the following default content:
    - `date-time`
    - `date`
    - `time`
    - `ipv4`
    - `ipv6`

    To disable these filters, pass `false` to the path, e.g.
    `%{"/" => false}` or `%{"/foo/bar/" => false}`. To specify a custom format
    filter, pass either function/args or mfa to the path, e.g.
    `%{"/path/to/fun" => {Module, :fun, [123]}}` or if you want the f/a or mfa
    to apply to all tags of a given format string, create use the atom of the
    type name as the key for your map.

    The corresponding function will be called with thue candidate formatted
    string as the first argument and the supplied arguments after.  If you use
    the function/args (e.g. `{:private_function, [123]}`) it may be a private
    function in the same module.  The custom function should return `true` on
    successful validation and `false` on failure.

    `date-time` ships with the parameter `:utc` which you may pass as
    `%{"/path/to/date-time/" => [:utc]}` that forces the date-time to be an
    ISO-8601 datetime string.

  - `:entrypoint`: a JSONpointer to the internal location inside of a json
    document where you would like to start the JSONschema.  This should be in
    JSONPointer form.  See https://datatracker.ietf.org/doc/html/rfc6901 for
    more information about JSONPointer

  - `:decoder`: specify `{module, function}` to use as the decoder for the text
    that turns into JSON (e.g. YAML instead of JSON)

  - `:draft`: specifies any special draft information.  Defaults to "2020",
    which is intercompatible with `"2019"`.  `"4"`, `"6"`, and `"7"` are also
    supported.  Note: Validation is NOT performed on the schema, so
    intermingling draft components is possible (but not recommended).

  ### remoteRef schema retrieval

  - `:force_remote`: bypasses the manual prompt confirming if remote resources
    should be downoladed.  Use with caution!  Defaults to `false`.

  - `:cache`: if remote JSONs should be cached to the local filesystem.
    Defaults to `false`

  - `:cache_app`: specifies the otp app whose priv directory cached remote
    JSONs are stored. Defaults to `:exonerate`.

  - `:cache_path`: specifies the subdirectory of priv where cached remote JSONs
    are stored.  Defaults to `/`.

  - `:proxy`: a string proplist which describes string substitution of url
    resources for proxied remote content.

    ##### Example

    ``` elixir
    [proxy: [{"https://my.remote.resource/", "http://localhost:4000"}]]
    ```
  """

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Schema

  @doc """
  generates a series of functions that validates a provided JSONSchema.

  Note that the `schema` parameter must be a string literal.
  """
  defmacro function_from_string(type, function_name, schema_ast, opts \\ []) do
    # prewalk the schema text

    root_pointer = JsonPointer.from_uri("/")

    # TODO: also attempt to obtain this from the schema.
    draft = Keyword.get(opts, :draft, "2020-12")
    opts = Keyword.put(opts, :draft, draft)

    function_resource = %URI{scheme: "function", host: "#{function_name}", path: "/"}
    |> to_string
    |> String.to_atom

    schema =
      schema_ast
      |> Macro.expand(__CALLER__)
      |> Schema.ingest(__CALLER__, function_resource, opts)

    resource = if id = id_from(schema) do
      resource = :"#{id}"
      Cache.put_schema(__CALLER__.module, resource, schema)
      resource
    else
      function_resource
    end

    call = Tools.call(resource, root_pointer, opts)

    {schema_str, id} =
      if is_map(schema), do: {schema["$schema"], id_from(schema)}, else: {nil, nil}

    Tools.maybe_dump(
      quote do
        require Exonerate.Context
        Exonerate.schema(unquote(type), unquote(function_name), unquote(schema_str))
        Exonerate.id(unquote(type), unquote(function_name), unquote(id))

        unquote(type)(unquote(function_name)(value), do: unquote(call)(value, "/"))

        Exonerate.Context.filter(unquote(resource), unquote(root_pointer), unquote(opts))
      end,
      opts
    )
  end

  defp id_from(schema) when is_map(schema), do: schema["$id"] || schema["id"]
  defp id_from(_), do: nil

  @doc """
  generates a series of functions that validates a JSONschema in a file at
  the provided path.

  Note that the `path` parameter must be a string literal.
  """
  defmacro function_from_file(type, resource, path, opts \\ [])

  defmacro function_from_file(type, resource, path, opts) do
    raise "not yet"
    # opts =
    #  opts
    #  |> Keyword.merge(resource: Atom.to_string(name))
    #  |> resolve_opts(__CALLER__, @common_defaults)
    #
    # {schema, extra} =
    #  path
    #  |> Macro.expand(__CALLER__)
    #  |> Registry.get_file()
    #  |> case do
    #    {:cached, contents} ->
    #      {decode(contents, opts),
    #       [
    #         quote do
    #           @external_resource unquote(path)
    #         end
    #       ]}
    #
    #    {:loaded, contents} ->
    #      {decode(contents, opts), []}
    #  end
    #
    # Tools.maybe_dump(
    #  quote do
    #    unquote_splicing(extra)
    #    unquote(compile_json(type, name, schema, opts))
    #  end,
    #  opts
    # )
  end

  @doc false
  # private api.  Causes the $schema metadata to be accessible by passing the `:schema` atom.
  defmacro schema(type, function, schema) do
    if schema do
      quote do
        unquote(type)(unquote(function)(:schema), do: unquote(schema))
      end
    end
  end

  @doc false
  # private api.  Causes the $id metadata to be accessible by passing the `:id` atom.
  defmacro id(type, function, id) do
    if id do
      quote do
        unquote(type)(unquote(function)(:id), do: unquote(id))
      end
    end
  end
end
