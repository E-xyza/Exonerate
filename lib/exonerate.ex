defmodule Exonerate do

  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Validation

  # TODO: fill tihs out with more descriptive terms
  @type error :: {:error, keyword}

  defmacro defschema([{path, json} | opts]) do
    #path = Keyword.get(opts, :path, [])

    schema = json
    |> Macro.expand(__CALLER__)
    |> Jason.decode!

    #docstr = """
    #Defined by the jsonschema:
    #```
    ##{json}
    #```
    #"""

    #docblock = quote do
    #  if Module.get_attribute(__MODULE__, :schemadoc) do
    #    @doc """
    #    #{@schemadoc}
    #    #{unquote(docstr)}
    #    """
    #  else
    #    @doc unquote(docstr)
    #  end
    #end

    q = quote do
      unquote_splicing(id_special_ast(path, schema))
      unquote_splicing(schema_special_ast(path, schema))
      unquote_splicing(metadata_ast(path, schema))

      def unquote(path)(value) do
        unquote(:"#{path}#!/")(value, "/")
        :ok
      catch
        error = {:error, list} -> error
      end

      unquote(Validation.from_schema(schema, ["#{path}#!/"]))
    end

    if Atom.to_string(path) =~ "items" do
      q |> Macro.to_string |> IO.puts
    end

    q
  end

  # special forms
  defp id_special_ast(path, %{"$id" => id}) do
    [quote do
      def unquote(path)(:id), do: unquote(id)
    end]
  end
  defp id_special_ast(_, _), do: []

  defp schema_special_ast(path, %{"$schema" => schema}) do
    [quote do
      def unquote(path)(:schema), do: unquote(schema)
    end]
  end
  defp schema_special_ast(_, _), do: []

  @metadata_fields ~w(title description default examples)
  defp metadata_ast(_path, bool) when is_boolean(bool), do: []
  defp metadata_ast(path, schema_map) do
    Enum.flat_map(@metadata_fields, fn field ->
      if is_map_key(schema_map, field) do
        symbol = String.to_atom(field)
        [quote do
          def unquote(path)(unquote(symbol)), do: unquote(schema_map[field])
        end]
      else
        []
      end
    end)
  end

  #################################################################
  ## PRIVATE HELPER FUNCTIONS

  @spec join(atom, String.t | nil) :: atom
  @spec join(Path.t, String.t | nil) :: Path.t
  @doc false
  def join(path, nil), do: path
  def join(path, subpath) when is_atom(path) do
    path
    |> Atom.to_string
    |> join(subpath)
    |> String.to_atom
  end
  def join(path, subpath) do
    Path.join(path, subpath)
  end

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
      schema_path: unquote(schema_path!),
      error_value: unquote(value),
      json_path: unquote(path)}
    end
  end

  def path(schema_path) do
    schema_path
    |> Enum.reverse
    |> Path.join
    |> String.to_atom
  end
end
