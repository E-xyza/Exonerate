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

  ## Options

  The following options are available:

  - `:metadata`: `true` to enable all metadata decorator functions or a list of
    atoms parameters to enable.  The following metadata are accessible by passing
    the corresponding atom to the generated function in lieu of a JSON term to
    validate.

    | JSONschema tag  | atom parameter |
    |-----------------|----------------|
    | $id or id       | `:id`          |
    | $schema         | `:schema_id`   |
    | default         | `:default`     |
    | examples        | `:examples`    |
    | description     | `:description` |
    | title           | `:title`       |
    | <entire schema> | `:schema`      |

  - `:format`: instructions for using (optional) format filters.  This should be
    either `true` or a keyword list.

    - `true`: shorthand for `[default: true]`
    - keywords:
      - `:at`: a list of `{<json pointer>, <filter-spec>}` tuples to apply
        format filters in specific locations in the schema.  This can be used
        to specify custom filters for non-default format types.  It can also be
        used to override default formatting.  `<json pointer>` should be a
        string which may be relative if no `"id"` or `"$id"` metadata are
        present in the parents of the location.  Otherwise, the pointer must
        the a uri of the nearest parent containing `"id"` or `"$id" metadata,
        with the relative pointer applied as the fragment of the uri.
      - `:type`: a list of `{<format-type>, <filter-spec>}` to apply across
        the schema whenever `<format-type>` is encountered.  This can be used
        to specify custom filters for non-default format types.  It can also
        be used to override default formatting.
      - `:default`: `true` to enable all default filters or a list of strings
        specifying the default format types to enable.  The following format
        types are available:
        - `"date-time"`: enables the default date-time filter for all
          `{"format": "date-time"}` contexts.  This uses Elixir's
          `NaiveDateTime.from_iso8601/1` parser.
        - `"date-time-utc"`: enables the default date-time-utc filter for all
          `{"format": "date-time-utc"}` contexts.  This uses Elixir's
          `DateTime.from_iso8601/1` parser, and requires the offset to be
          0 from UTC.
        - `"date-time-tz"`: enables the default date-time filter for all
          `{"format": "date-time-tz"}` context strings.  This uses Elixir's
          `DateTime.from_iso8601/1` parser, which requires an offset to
          be specified.
        - `"date"`: enables the default date filter for all `{"format": "date"}`
          context strings.  This uses Elixir's `Date.from_iso8601/1` parser.
        - `"time"`: enables the default time filter for all `{"format": "time"}`
          context strings.  This uses Elixir's `Time.from_iso8601/1` parser.
        - `"duration": enables the default duration filter for all
          `{"format": "duration"}` context strings.  This uses a custom ABNF
          filter that matches Appendix A of RFC 3339: https://www.rfc-editor.org/rfc/rfc3339.txt
        - `"ipv4"`: enables the default ipv4 filter for all `{"format": "ipv4"}`
          context strings.  This uses Erlang's `:inet.parse_ipv4strict_address/1`
          parser.
        - `"ipv6"`: enables the default ipv6 filter for all `{"format": "ipv6"}`
          context strings.  This uses Erlang's `:inet.parse_ipv6strict_address/1`
          parser.
        - `"uuid"`: enables the default uuid filter for all `{"format": "uuid"}`
          context strings.
        - `"email"`: enables the default email filter for all `{"format": "email"}`
          context strings.  This uses a custom ABNF filter that matches section 4.1.2
          of RFC 5322: https://www.rfc-editor.org/rfc/rfc5322.txt
        - `"idn-email"`: enables the default idn-email (i18n email address)
          filter for all `{"format": "idn-email"}` context strings.  This uses a
          custom ABNF filter that matches section 3.3 of RFC 6531:
          https://www.rfc-editor.org/rfc/rfc5322.txt
        - `"hostname"`: enables the default hostname filter for all
          `{"format": "hostname"}` context strings.  This uses a custom ABNF
          filter that matches section 2.1 of RFC 1123:
          https://www.rfc-editor.org/rfc/rfc1123.txt
        - `"idn-hostname"`: enables the default idn-hostname (i18n hostname)
          filter for all `{"format": "idn-hostname"}` context strings.

          Note that in order to use this filter, you must add the
          `:idna` library to your dependencies.
        - `"uri"`: enables the default uri filter for all `{"format": "uri"}`
          context strings.  This uses a custom ABNF filter that matches section
          3 of RFC 3986: https://www.rfc-editor.org/rfc/rfc3986.txt.  Note that
          a these uris must be absolute, i.e. they must contain a scheme, host,
          and path.
        - `"uri-reference"`: enables the default uri-reference filter for all
          `{"format": "uri-reference"}` context strings.  This uses a custom ABNF
          filter that matches section 3 of RFC 3986:
          https://www.rfc-editor.org/rfc/rfc3986.txt.  Note that a these uris
          may be relative, i.e. do not need to contain a scheme, host, and path.
        - `"iri"`: enables the default iri (i18n uri) filter for all
          `{"format": "iri"}` context strings.  This uses a custom ABNF filter
          that matches section 2.2 of RFC 3987: https://www.rfc-editor.org/rfc/rfc3987.txt.
          Note that a these iris must be absolute, i.e. they must contain a
          scheme, host, and path.
        - `"iri-reference"`: enables the default iri-reference (i18n uri) for all
          `{"format": "iri-reference"}` context strings.  This uses a custom ABNF
          filter that matches section 2.2 of RFC 3987: https://www.rfc-editor.org/rfc/rfc3987.txt.
          Note that a these iris may be relative, i.e. do not need to contain a
          scheme, host, and path.
        - `"uri-template"`: enables the default uri-template filter for all
          `{"format": "uri-template"}` context strings.  This uses a custom ABNF
          filter that matches section 2.3 of RFC 6570: https://www.rfc-editor.org/rfc/rfc6570.txt.
          Note that uri-templates are templated against iri-reference strings.
        - `"json-pointer"`: enables the default json-pointer filter for all
          `{"format": "json-pointer"}` context strings.  This uses a custom ABNF
          filter that matches section 3 of RFC 6901: https://www.rfc-editor.org/rfc/rfc6901.txt
        - `"relative-json-pointer"`: enables the default relative-json-pointer
          filter for all `{"format": "relative-json-pointer"}` context strings.
          This uses a custom ABNF filter that matches the followowing rfc proposal:
          https://datatracker.ietf.org/doc/html/draft-handrews-relative-json-pointer-01
        - `"regex"`: enables the default regex filter for all `{"format": "regex"}`
          context strings.  Note: this does not compile the regex, instead it
          uses a custom ABNF filter that matches the ECMA-262 standard:
          https://www.ecma-international.org/publications-and-standards/standards/ecma-262/

  - `:entrypoint`: a JSONpointer to the internal location inside of a json
    document where you would like to start the JSONschema.  This should be in
    JSONPointer form.  See https://datatracker.ietf.org/doc/html/rfc6901 for
    more information about JSONPointer

  - `:decoder`: specify `{module, function}` to use as the decoder for the text
    that turns into JSON (e.g. YAML instead of JSON)

  - `:draft`: specifies any special draft information.  Defaults to "2020",
    which is intercompatible with `"2019"`.  `"4"`, `"6"`, and `"7"` are also
    supported.  Note: Validation is NOT performed on the schema, so
    intermingling draft components is possible (but not recommended).  This overrides
    draft information provided in the schema

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
  alias Exonerate.Metadata
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

    function_resource = to_string(%URI{scheme: "function", host: "#{function_name}", path: "/"})

    schema_string = Macro.expand(schema_ast, __CALLER__)
    schema = Schema.ingest(schema_string, __CALLER__, function_resource, opts)

    resource =
      if id = id_from(schema) do
        resource = id
        Cache.put_schema(__CALLER__.module, resource, schema)
        resource
      else
        function_resource
      end

    call = Tools.call(resource, root_pointer, opts)

    schema_fn = Metadata.schema(schema_string, type, function_name, opts)

    Tools.maybe_dump(
      quote do
        require Exonerate.Metadata

        unquote(schema_fn)

        Exonerate.Metadata.functions(
          unquote(type),
          unquote(function_name),
          unquote(resource),
          unquote(root_pointer),
          unquote(opts)
        )

        unquote(type)(unquote(function_name)(value), do: unquote(call)(value, "/"))

        require Exonerate.Context
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
end
