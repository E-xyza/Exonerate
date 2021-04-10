defmodule Exonerate do

  @moduledoc """
    creates the defschema macro.
  """

  @type json ::
     %{optional(String.t) => json}
     | list(json)
     | String.t
     | number
     | boolean
     | nil

  # TODO: fill tihs out with more descriptive terms
  @type error :: {:error, keyword}

  alias Exonerate.Builder
  alias Exonerate.Buildable

  defmacro defschema([{path, json} | opts]) do
    #path = Keyword.get(opts, :path, [])

    schema_map = json
    |> Macro.expand(__CALLER__)
    |> Jason.decode!

    schema = Builder.build(schema_map, :"#{path}#!/", opts)

    schema_ast = schema
    |> Buildable.build()
    |> List.wrap

    #docstr = """
    #Matches JSONSchema:
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

    quote do
      require Exonerate.Builder

      unquote_splicing(id_special_ast(path, schema_map))
      unquote_splicing(schema_special_ast(path, schema_map))
      unquote_splicing(metadata_ast(path, schema_map))

      def unquote(path)(value) do
        unquote(schema.path)(value, "/")
      catch
        {:mismatch, list} -> {:error, list}
      end

      unquote_splicing(schema_ast)

      unquote_splicing(verification_ast(path, schema_map))
    end
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

  # verify that default and examples must satisfy the schema
  @verifying_fields ~w(default examples)
  defp verification_ast(path, schema_map) do
    Enum.flat_map(@verifying_fields, fn field ->
      if is_map_key(schema_map, field) do
        verification = :foobar
        [quote do
          @after_compile {__MODULE__, unquote(verification)}

          def foobar(env, bytecode) do
            IO.puts("hi mom")
          end
        end]
      else
        []
      end
    end)
  end

end
