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

  @type mismatch :: {:mismatch, Path.t, json}

  alias Exonerate.Builder
  alias Exonerate.Buildable

  defmacro defschema([{method, json} | opts]) do
    #path = Keyword.get(opts, :path, [])

    schema_map = json
    |> Macro.expand(__CALLER__)
    |> Jason.decode!

    schema_ast = schema_map
    |> Builder.build(method, opts)
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

    q = quote do
      unquote_splicing(id_special_ast(method, schema_map))
      unquote_splicing(schema_special_ast(method, schema_map))

      def unquote(method)(value) do
        unquote(method)(value, "#")
      catch
        {:mismatch, list} -> {:error, list}
      end

      unquote_splicing(schema_ast)
    end

    q |> Macro.to_string |> IO.puts
    q
  end

  # special forms
  defp id_special_ast(method, %{"$id" => id}) do
    [quote do
      def unquote(method)(:id), do: unquote(id)
    end]
  end
  defp id_special_ast(_, _), do: []

  defp schema_special_ast(method, %{"$schema" => schema}) do
    [quote do
      def unquote(method)(:schema), do: unquote(schema)
    end]
  end
  defp schema_special_ast(_, _), do: []

end
