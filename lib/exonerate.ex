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

      def unquote(path)(value) do
        unquote(schema.path)(value, "/")
      catch
        {:mismatch, list} -> {:error, list}
      end

      unquote_splicing(schema_ast)
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

end
