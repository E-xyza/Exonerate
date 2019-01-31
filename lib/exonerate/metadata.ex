defmodule Exonerate.Metadata do

  alias Exonerate.Annotate

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type annotated_ast :: Exonerate.annotated_ast

  @spec set_title(specmap, String.t, atom) :: [annotated_ast]
  def set_title(spec, title, method) do
    rest = spec
    |> Map.delete("title")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:title) :: String.t
        defp unquote(method)(:title), do: unquote(title)
      end
    | rest]
  end

  @spec set_description(specmap, String.t, atom) :: [annotated_ast]
  def set_description(spec, description, method) do
    rest = spec
    |> Map.delete("description")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:description) :: String.t
        defp unquote(method)(:description), do: unquote(description)
      end
    | rest]
  end

  @spec set_default(specmap, json, atom) :: [annotated_ast]
  def set_default(spec, default, method) do
    rest = spec
    |> Map.delete("default")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:default) :: Exonerate.json
        defp unquote(method)(:default), do: unquote(default)
      end
    | rest]
  end

  @spec set_examples(specmap, [json], atom) :: [annotated_ast]
  def set_examples(spec, examples, method) do
    rest = spec
    |> Map.delete("examples")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:examples) :: [Exonerate.json]
        defp unquote(method)(:examples), do: unquote(examples)
      end
    | rest]
  end

  @spec set_schema(specmap, String.t, atom) :: [annotated_ast]
  def set_schema(map, schema, method) do
    rest = map
    |> Map.delete("$schema")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:schema) :: String.t
        defp unquote(method)(:schema), do: unquote(schema)
      end
    | rest]
  end

  @spec set_id(map, String.t, atom) :: [annotated_ast]
  def set_id(map, id, method) do
    rest = map
    |> Map.delete("$id")
    |> Exonerate.matcher(method)

    [ Annotate.public(method),
      quote do
        @spec unquote(method)(:id) :: String.t
        defp unquote(method)(:id), do: unquote(id)
      end
    | rest]
  end

end
