defmodule Exonerate do
  alias Exonerate.Pointer
  alias Exonerate.Type
  alias Exonerate.Registry
  alias Exonerate.Validator

  defmacro function_from_string(type, name, schema, opts \\ [])
  defmacro function_from_string(:def, name, schema_json, opts) do
    entrypoint = opts
    |> Keyword.get(:entrypoint, "/")
    |> Pointer.from_uri

    opts = Keyword.merge(opts, authority: Atom.to_string(name))

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
    end |> Exonerate.Tools.inspect(name == :dependentSchemas_0)
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
