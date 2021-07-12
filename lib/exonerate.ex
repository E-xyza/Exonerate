defmodule Exonerate do
  alias Exonerate.Pointer
  alias Exonerate.Type
  alias Exonerate.Validator

  defmacro function_from_string(type, name, schema, opts \\ [])
  defmacro function_from_string(:def, name, schema_json, opts) do
    entrypoint = opts
    |> Keyword.get(:entrypoint, "/")
    |> Pointer.from_uri

    opts = Keyword.merge(opts, authority: Atom.to_string(name))

    schema_erl = schema_json
    |> Macro.expand(__CALLER__)
    |> Jason.decode!

    impl = schema_erl
    |> Validator.parse(entrypoint, opts)
    |> Validator.compile

    json_type = {:"#{name}_json", [], []}

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

      unquote_splicing(metadata_functions(name, schema_erl, entrypoint))

      def unquote(name)(value) do
        try do
          unquote(Pointer.to_fun(entrypoint, opts))(value, "/")
        catch
          error = {:error, e} when is_list(e) -> error
        end
      end

      unquote(impl)
    end
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

  defp build_pipe(input_ast, path_ast, [{fun, args} | rest]) do
    build_pipe({:|>, [], [input_ast, {fun, [], [path_ast | args]}]}, path_ast, rest)
  end
  defp build_pipe(input_ast, _path_ast, []), do: input_ast

  # TODO: generalize these.

  @doc false
  defmacro chain_guards(variable_ast, types) do
    types
    |> Enum.map(&apply_guard(&1, variable_ast))
    |> Enum.reduce(&{:or, [], [&1, &2]})
  end

  defp apply_guard(type, variable_ast), do: {Type.guard(type), [], [variable_ast]}
end
