defmodule Exonerate do
  @moduledoc """
  An opinionated JSONSchema compiler for elixir.

  Currently supports JSONSchema draft 0.7.  *except:*

  - integer filters do not match exact integer floating point values.
  - multipleOf is not supported for number types.  This is because
  elixir does not support a floating point remainder guard, and also
  because it is impossible for a floating point to guarantee sane results
  (e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
  - currently remoteref is not supported.

  For details, see:  http://json-schema.org

  ## Usage

  Exonerate is 100% compile-time generated.  You should include Exonerate with
  the `runtime: false` option in `Mix.exs`.

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
  atom.

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

  - `:format_options`: a map of JSONpointers to tags with corresponding `{"format" => "..."}` filters.
    Exonerate ships with filters for the following default content:
    - `date-time`
    - `date`
    - `time`
    - `ipv4`
    - `ipv6`

    To disable these filters, pass `false` to the path, e.g. `%{"/" => false}` or `%{"/foo/bar/" => false}`.
    To specify a custom format filter, pass either function/args or mfa to the path, e.g.
    `%{"/path/to/fun" => {Module, :fun, [123]}}` The corresponding function will be called with the string as the
    first argument and the supplied arguments after.  If you use the function/args (e.g. `{:private_function, [123]}`)
    it may be a private function in the same module.  The custom function should return `true` on successful
    validation and `false` on failure.

    `date-time` ships with the parameter `:utc` which you may pass as `%{"/path/to/date-time/" => [:utc]}` that
    forces the date-time to be an ISO-8601 datetime string.

  - `:entrypoint`: a JSONpointer to the internal location inside of a json document where you would like to start
    the JSONschema.  A json document might contain multiple schemasFor example:

    ```
      multischema = \"""
      {
        "schema1": {"type": "string"},
        "schema2": {"type": "number"}
      }
      \"""

      Exonerate.function_from_string(:def, :schema1, multischema, entrypoint: "/schema1")
      Exonerate.function_from_string(:def, :schema2, multischema, entrypoint: "/schema2")
    ```

    In more practical terms, this enables you to store single documents and reuse components, especially when
    combined with `$ref` tags.  Exonerate will be parsimonious and minimize producing multiple functions for
    validation trees so long as the instantiated functions are within the same module.
  """

  alias Exonerate.Pointer
  alias Exonerate.Type
  alias Exonerate.Registry
  alias Exonerate.Validator

  defmacro function_from_string(type, name, schema, opts \\ [])
  defmacro function_from_string(:def, name, schema_json, opts) do
    entrypoint = opts
    |> Keyword.get(:entrypoint, "/")
    |> Pointer.from_uri

    format_options = opts[:format_options]
    |> Code.eval_quoted([], __CALLER__)
    |> elem(0)
    |> Kernel.||(%{})

    opts = Keyword.merge(opts,
      authority: Atom.to_string(name),
      format_options: format_options)

    schema = schema_json
    |> Macro.expand(__CALLER__)
    |> Jason.decode!

    impl = schema
    |> Validator.parse(entrypoint, opts)
    |> Validator.compile

    json_type = {:"#{name}_json", [], []}

    # let's see if there's anything leftover.
    dangling_refs = unroll_refs(schema)

    quote do
      @typep unquote(json_type) ::
        bool
        | nil
        | number
        | String.t
        | [unquote(json_type)]
        | %{String.t => unquote(json_type)}

      @spec unquote(name)(unquote(json_type)) :: :ok |
        {:error, [
          schema_pointer: Path.t,
          error_value: term,
          json_pointer: Path.t
        ]}

      unquote_splicing(metadata_functions(name, schema, entrypoint))

      def unquote(name)(value) do
        try do
          unquote(Pointer.to_fun(entrypoint, opts))(value, "/")
        catch
          error = {:error, e} when is_list(e) -> error
        end
      end

      unquote(impl)
      unquote(dangling_refs)
    end # |> Exonerate.Tools.inspect(name == :maxProperties_1)
  end

  @metadata_call %{
    "$id" => :id,
    "$schema" => :schema,
    "default" => :default,
    "examples" => :examples,
    "description" => :description,
    "title" => :title
  }

  @metadata_keys Map.keys(@metadata_call)
  defp metadata_functions(name, schema, entrypoint) do
    case Pointer.eval(entrypoint, schema) do
      bool when is_boolean(bool) -> []
      map when is_map(map) ->
        for {k, v} when k in @metadata_keys <- map do
          call = @metadata_call[k]
          quote do
            @spec unquote(name)(unquote(call)) :: String.t
            def unquote(name)(unquote(call)) do
              unquote(v)
            end
          end
        end
    end
  end

  defp unroll_refs(schema) do
    case Registry.needed(schema) do
      [] -> []
      list when is_list(list) ->
        ref_impls = Enum.map(list, fn ref ->
          schema
          |> Validator.parse(ref.pointer, authority: ref.authority)
          |> Validator.compile
        end)
        # keep going!  This schema might have created new refs.
        ref_impls ++ unroll_refs(schema)
    end
  end

  #################################################################
  ## PRIVATE HELPER FUNCTIONS

  @doc false
  defmacro mismatch(value, path, opts \\ []) do
    schema_path! = __CALLER__.function
    |> elem(0)
    |> to_string

    schema_path! = if guard = opts[:guard] do
      quote do
        Path.join(unquote(schema_path!), unquote(guard))
      end
    else
      schema_path!
    end

    quote do
      throw {:error,
      schema_pointer: unquote(schema_path!),
      error_value: unquote(value),
      json_pointer: unquote(path)}
    end
  end

  @doc false
  defmacro pipeline(variable_ast, path_ast, pipeline) do
    build_pipe(variable_ast, path_ast, pipeline)
  end

  defp build_pipe(input_ast, params_ast, [fun | rest]) do
    build_pipe({:|>, [], [input_ast, {fun, [], [params_ast]}]}, params_ast, rest)
  end
  defp build_pipe(input_ast, _params_ast, []), do: input_ast

  # TODO: generalize these.

  @doc false
  defmacro chain_guards(variable_ast, types) do
    types
    |> Enum.map(&apply_guard(&1, variable_ast))
    |> Enum.reduce(&{:or, [], [&1, &2]})
  end

  defp apply_guard(type, variable_ast), do: {Type.guard(type), [], [variable_ast]}
end
