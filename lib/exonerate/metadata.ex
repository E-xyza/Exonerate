defmodule Exonerate.Metadata do

  alias Exonerate.Annotate
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type parser   :: Exonerate.Parser.t

  @spec set_title(specmap, parser, String.t, atom) :: parser
  def set_title(spec, parser!, title, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:title) :: String.t
        defp unquote(method)(:title), do: unquote(title)
      end
    ])

    spec
    |> Map.delete("title")
    |> Parser.match(parser!, method)
  end

  @spec set_description(specmap, parser, String.t, atom) :: parser
  def set_description(spec, parser!, description, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:description) :: String.t
        defp unquote(method)(:description), do: unquote(description)
      end
    ])

    spec
    |> Map.delete("description")
    |> Parser.match(parser!, method)
  end

  @spec set_default(specmap, parser, json, atom) :: parser
  def set_default(spec, parser!, default, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:default) :: Exonerate.json
        defp unquote(method)(:default), do: unquote(default)
      end
    ])

    spec
    |> Map.delete("default")
    |> Parser.match(parser!, method)
  end

  @spec set_examples(specmap, parser, [json], atom) :: parser
  def set_examples(spec, parser!, examples, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:examples) :: [Exonerate.json]
        defp unquote(method)(:examples), do: unquote(examples)
      end
    ])

    spec
    |> Map.delete("examples")
    |> Parser.match(parser!, method)
  end

  @spec set_schema(specmap, parser, String.t, atom) :: parser
  def set_schema(spec, parser!, schema, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:schema) :: String.t
        defp unquote(method)(:schema), do: unquote(schema)
      end
    ])

    spec
    |> Map.delete("$schema")
    |> Parser.match(parser!, method)
  end

  @spec set_id(map, parser, String.t, atom) :: parser
  def set_id(spec, parser!, id, method) do
    parser! = parser!
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:id) :: String.t
        defp unquote(method)(:id), do: unquote(id)
      end
    ])

    spec
    |> Map.delete("$id")
    |> Parser.match(parser!, method)
  end

end
