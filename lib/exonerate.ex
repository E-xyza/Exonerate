defmodule Exonerate do
  @moduledoc """
  An opinionated JSONSchema compiler for elixir.

  Currently supports JSONSchema drafts 4, 6, 7, 2019, and 2020.  *except:*

  - multipleOf is not supported for number types.  This is because
  elixir does not support a floating point remainder guard, and also
  because it is impossible for a floating point to guarantee sane results
  (e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
  - id fields with fragments in their uri identifier (draft 7 and earlier only)
  - dynamicRefs and anchors.
  - contentMediaType, contentEncoding, contentSchema

  For details, see:  http://json-schema.org

  Exonerate is automatically tested against the JSONSchema test suite.

  Note that Exonerate does *not* generally validate that the schema presented to it
  is valid, unless the violation results in an uncompilable entity.

  ## Usage

  Exonerate yields 100% compile-time generated code.  You may include Exonerate
  with the `runtime: false` option in `mix.exs`, unless you believe you will
  need to edit and recompile modules with Exonerate at runtime.

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

  The above module generates a function `MyModule.function_name/1` that takes an BEAM JSON term
  (`string | number | list | map | bool | nil`) and validates it based on the the JSONschema.  If
  the term validates, it produces `:ok`.  If the term fails to validate, it produces
  `{:error, keyword}`, where the key `:instance_location` and points to the error location in the passed
  parameter, the `:schema_pointers` points to the validation that failed, and `error_value` is the
  failing inner term.

  ## Error keywords

  The following error keywords conform to the JSONSchema spec
  (https://json-schema.org/draft/2020-12/json-schema-core.html#name-format):

  - `:absolute_keyword_location`: a JSON pointer to the keyword in the schema that failed.
  - `:instance_location`: a JSON pointer to the location in the instance that failed.
  - `:errors`: a list of errors generated when a combining filter fails to match.

  The following error keywords are not standard and are specific to Exonerate:

  - `:error_value`: the innermost term that failed to validate.
  - `:matches`: a list of JSON pointers to the keywords that matched a combining filter.
  - `:reason`: a string describing the error, when the failing filter can fail for nonobvious
    reasons.  For example `oneOf` will fail with the reason "no matches" when none of the
    child schemas match; but it will fail with the reason "multiple matches" when more than
    of the child schemas match.
  - `:required`: a list of object keys that were required but missing.
  - `:ref_trace`: a list of `$ref` keywords that were followed to get to the failing keyword.

  ## Options

  The following options are available:

  - `:dump`: `true` to dump the generated code to the console.  Note that this
    will create function names that aren't the function names when compiled otherwise,
    but adjusted so that you can copy/paste them into the elixir console.  This could
    cause collisions when more than one dumped templates are present in the same module.

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

  - `:format`: instructions for using (optional) format filters.  Pass `true`
    to enable all default format filters, or a keyword list for fine-grained
    control.  See the [Format Filters guide](guides/formatting.md) for complete
    documentation of all available format types and custom filter configuration.

  - `:entrypoint`: a JSONpointer to the internal location inside of a json
    document where you would like to start the JSONschema.  This should be in
    JSONPointer form (not URI form).  See https://datatracker.ietf.org/doc/html/rfc6901
    for more information about JSONPointer

  - `:decoders`: a list of `{<mimetype>, <decoder>}` tuples.  `<encoding-type>`
    should be a string that matches the `content-type` of the schema. `<decoder>`
    should be one of the following:
    - `Jason` (default) for json parsing
    - `YamlElixir` for yaml parsing
    - `{module, function}` for custom parsing; the function should accept a
      string and return json term, raising if the string is not valid input
      for the decoder.

    Defaults to `[{"application/json", Jason}, {"application/yaml", YamlElixir}]`.
    Tuples specified in this option will override or add to the defaults.

  - `:draft`: specifies any special draft information.  Defaults to `"2020"`,
    `"2019"`, `"4"`, `"6"`, and `"7"` are also supported. This overrides draft
    information provided in the schema

    > ### Validation {: .warning}
    >
    > Validation is NOT performed on the schema, so intermingling draft
    > components is possible (but not recommended).  In the future, using
    > components in the wrong draft may cause a compile-time warning.

  ### remoteRef schema retrieval options

  - `:remote_fetch_adapter`: specifies the module to use for fetching remote
    resources.  This module must export a `fetch_remote!/2` function which
    is passed a `t:URI.t/0` struct and returns `{<body>, <content-type>}` pair.
    content-type may be `nil`.  Defaults to `Exonerate.Remote`, which uses the
    `Req` library to perform the http request.

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

    #### Example

    ``` elixir
    [proxy: [{"https://my.remote.resource/", "http://localhost:4000"}]]
    ```
  """

  alias Exonerate.Cache
  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Metadata
  alias Exonerate.Schema

  @doc """
  saves in the compile-time registry a schema under the given name.  The schema
  can then be used to generate a validation function with
  `function_from_resource/3`.  This is useful for clearly reusing a string
  schema across multiple functions with potentially different entrypoints, but
  without having to repeat the (potentially large) schema string literal in
  your module code.

  > ### Note {: .info}
  >
  > this function is optional, `function_from_string/4` will also create a
  > resource for the string and reuse private functions between calls.

  > ### File schemas {: .info}
  >
  > `function_from_file/4` will perform the equivalent of this process under
  > the hood, so don't run this function for file functions.

  ### Extra options

  - `:content_type`: specifies the MIME type used to parse the *schema definition
    itself* (not the data being validated at runtime). This tells Exonerate how
    to decode the schema string into an Elixir map. Supported values:
    - `"application/json"` (default for `.json` files) - parse schema as JSON
    - `"application/yaml"` (default for `.yaml` files) - parse schema as YAML
      (requires the `yaml_elixir` dependency)

    > ### Important distinction {: .info}
    >
    > This option controls how the *schema file* is parsed at compile time, not
    > how validated data is parsed at runtime. The generated validation function
    > always works on already-decoded Elixir terms (maps, lists, strings, etc.).

    #### Example: YAML schema

    ```elixir
    # Using a YAML-formatted schema file
    Exonerate.function_from_file(:def, :validate, "schema.yaml")
    # content_type is auto-detected from .yaml extension

    # Using a YAML string directly
    Exonerate.function_from_string(:def, :validate, \"\"\"
    type: object
    properties:
      name:
        type: string
    \"\"\", content_type: "application/yaml")
    ```

  - `:mimetype_mapping`: a proplist of `{<extension>, <mimetype>}` tuples that
    maps file extensions to their content type. Use this when working with
    non-standard file extensions.

    #### Example

    ```elixir
    # Parse .schema files as JSON
    Exonerate.function_from_file(
      :def,
      :validate,
      "types.schema",
      mimetype_mapping: [{".schema", "application/json"}]
    )
    ```

    The built-in mappings `{".json", "application/json"}` and
    `{".yaml", "application/yaml"}` cannot be overridden.
  """
  defmacro register_resource(schema, name, opts \\ []) do
    schema = Macro.expand(schema, __CALLER__)
    opts = set_resource_opts(__CALLER__, opts)

    Cache.register_resource(__CALLER__.module, schema, name, opts)

    quote do
    end
  end

  @doc """
  generates a series of functions that validates a provided JSONSchema.

  Note that the `schema` parameter must be a string literal.

  ### Extra options

  The options described at the top of the module are available to this macro,
  in addition to the options described in `register_resource/3`
  """
  defmacro function_from_string(type, function_name, schema_ast, opts \\ []) do
    opts = set_resource_opts(__CALLER__, opts)

    # find or register the function.
    resource = Cache.find_or_make_resource(__CALLER__.module, schema_ast, opts)

    # prewalk the schema text
    root_pointer = Tools.entrypoint(opts)

    # TODO: also attempt to obtain this from the schema.
    draft = Keyword.get(opts, :draft, "2020-12")
    opts = Keyword.put(opts, :draft, draft)

    schema_string = Macro.expand(schema_ast, __CALLER__)

    build_code(
      __CALLER__,
      schema_string,
      type,
      function_name,
      "#{resource.uri}",
      root_pointer,
      opts
    )
  end

  defp id_from(schema) when is_map(schema), do: schema["$id"] || schema["id"]
  defp id_from(_), do: nil

  @doc """
  generates a series of functions that validates a JSONschema in a file at
  the provided path.

  Note that the `path` parameter must be a `t:Path.t/0` value.  The function
  names will contain the file url.

  ### Options

  The options described at the top of the module are available to this macro,
  in addition to the options described in `register_resource/3`
  """
  defmacro function_from_file(type, function_name, path, opts \\ [])

  defmacro function_from_file(type, function_name, path, opts) do
    # Read and potentially decompress the file
    {schema_string, actual_path} = read_and_decompress(path)

    # expand literals (aliases) in ast.
    # Use actual_path (with .gz stripped) for content_type detection
    opts =
      opts
      |> Macro.expand_literals(__CALLER__)
      |> set_content_type(actual_path)
      |> Tools.set_decoders()

    # prewalk the schema text
    root_pointer = Tools.entrypoint(opts)

    # TODO: also attempt to obtain this from the schema.
    draft = Keyword.get(opts, :draft, "2020-12")
    opts = Keyword.put(opts, :draft, draft)

    function_resource = to_string(%URI{scheme: "file", host: "", path: Path.absname(path)})

    # set decoder options for the schema

    build_code(
      __CALLER__,
      schema_string,
      type,
      function_name,
      function_resource,
      root_pointer,
      opts
    )
  end

  @doc """
  generates a series of functions from a previously provided JSONSchema found
  registered using `register_resource/3`.

  Note that the `resource` parameter must be a string literal defined earlier
  in a `register_resource/3` call

  ### Options

  Only supply options described in the module section.
  """

  defmacro function_from_resource(type, function_name, resource, opts \\ []) do
    # expand literals (aliases) in ast.
    opts = Macro.expand_literals(opts, __CALLER__)

    # prewalk the schema text
    root_pointer = Tools.entrypoint(opts)

    # TODO: also attempt to obtain this from the schema.
    draft = Keyword.get(opts, :draft, "2020-12")
    opts = Keyword.put(opts, :draft, draft)

    resource = Cache.fetch_resource!(__CALLER__.module, resource)

    # set decoder options for the schema

    build_code(
      __CALLER__,
      resource.schema,
      type,
      function_name,
      "#{resource.uri}",
      root_pointer,
      Keyword.merge(opts, resource.opts)
    )
  end

  defp build_code(
         caller,
         schema_string,
         type,
         function_name,
         resource_uri,
         root_pointer,
         opts
       ) do
    schema = Schema.ingest(schema_string, caller, resource_uri, opts)

    opts = Draft.set_opts(opts, schema)

    resource =
      if id = id_from(schema) do
        resource = id
        Cache.put_schema(caller.module, resource, schema)

        resource
      else
        resource_uri
      end

    # Phase 1: Collect all declarations before generating code
    Exonerate.Context.collect_declarations(caller.module, resource, root_pointer, opts)

    # Phase 2: Generate code (all declarations are now known)
    schema_fn = Metadata.schema(schema_string, type, function_name, opts)

    call = Tools.call(resource, root_pointer, opts)

    # Extract types from root schema for @spec generation
    root_schema = JsonPtr.resolve_json!(schema, root_pointer)
    input_typespec = build_input_typespec(root_schema)

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

        @spec unquote(function_name)(unquote(input_typespec)) :: :ok | {:error, list()}
        unquote(type)(unquote(function_name)(data), do: unquote(call)(data, "/"))

        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(root_pointer), unquote(opts))
      end,
      caller,
      opts
    )
  end

  defp build_input_typespec(root_schema) when is_map(root_schema) do
    case Map.get(root_schema, "type") do
      nil ->
        # No type constraint - accept any JSON
        quote(do: Exonerate.Type.json())

      types when is_list(types) ->
        Tools.spec_from_only(types)

      type when is_binary(type) ->
        Tools.spec_from_only([type])
    end
  end

  defp build_input_typespec(_), do: quote(do: Exonerate.Type.json())

  defp set_content_type(opts, path) do
    # need to support "encoding" option for backwards compatibility
    Keyword.put_new_lazy(opts, :content_type, fn ->
      if encoding = Keyword.get(opts, :encoding) do
        IO.warn("the `:encoding` option is deprecated.  use `:content_type` instead")
        encoding
      else
        Tools.content_type_from_extension(path, opts)
      end
    end)
  end

  defp set_resource_opts(caller, opts) do
    opts
    |> Macro.expand(caller)
    |> Macro.expand_literals(caller)
    |> handle_encoding_deprecation()
    |> Keyword.put_new(:content_type, "application/json")
    |> Tools.set_decoders()
  end

  defp handle_encoding_deprecation(opts) do
    if encoding = Keyword.get(opts, :encoding) do
      IO.warn("the `:encoding` option is deprecated.  use `:content_type` instead")
      Keyword.put_new(opts, :content_type, encoding)
    else
      opts
    end
  end

  defp read_and_decompress(path) do
    binary = File.read!(path)

    if String.ends_with?(path, ".gz") do
      decompressed = :zlib.gunzip(binary)
      # Strip .gz to get actual extension for content_type detection
      actual_path = String.replace_suffix(path, ".gz", "")
      {decompressed, actual_path}
    else
      {binary, path}
    end
  end
end
