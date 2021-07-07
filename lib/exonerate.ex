defmodule Exonerate do
  alias Exonerate.Validator
  alias Exonerate.Pointer

  defmacro function_from_string(type, name, schema, opts \\ [])
  defmacro function_from_string(:def, name, schema, opts) do
    entrypoint = opts
    |> Keyword.get(:entrypoint, "/")
    |> Pointer.from_uri

    opts = Keyword.merge(opts, context: Atom.to_string(name) <> "#")

    impl = schema
    |> Macro.expand(__CALLER__)
    |> Jason.decode!
    |> Validator.parse(entrypoint, opts)
    |> Validator.compile

    quote do
      @spec unquote(name)(map) :: :ok |
        {:error, [
          schema_pointer: Path.t,
          error_value: term,
          json_pointer: Path.t
        ]}
      def unquote(name)(value) do
        try do
          unquote(Pointer.to_fun(entrypoint, opts))(value, "/")
        catch
          error = {:error, e} when is_list(e) -> error
        end
      end

      unquote(impl)
    end # |> Exonerate.Tools.inspect
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
end
