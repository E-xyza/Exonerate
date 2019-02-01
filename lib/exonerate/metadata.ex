defmodule Exonerate.Metadata do

  alias Exonerate.Annotate
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec set_title(Parser.t, specmap, String.t) :: Parser.t
  def set_title(parser, spec, title) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:title) :: String.t
        defp unquote(parser.method)(:title), do: unquote(title)
      end
    ])
    |> Parser.match(Map.delete(spec, "title"))
  end

  @spec set_description(Parser.t, specmap, String.t) :: Parser.t
  def set_description(parser, spec, description) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:description) :: String.t
        defp unquote(parser.method)(:description), do: unquote(description)
      end
    ])
    |> Parser.match(Map.delete(spec, "description"))
  end

  @spec set_default(Parser.t, specmap, json) :: Parser.t
  def set_default(parser, spec, default) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:default) :: Exonerate.json
        defp unquote(parser.method)(:default), do: unquote(default)
      end
    ])
    |> Parser.match(Map.delete(spec, "default"))
  end

  @spec set_examples(Parser.t, specmap, [json]) :: Parser.t
  def set_examples(parser, spec, examples) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:examples) :: [Exonerate.json]
        defp unquote(parser.method)(:examples), do: unquote(examples)
      end
    ])
    |> Parser.match(Map.delete(spec, "examples"))
  end

  @spec set_schema(Parser.t, specmap, String.t) :: Parser.t
  def set_schema(parser, spec, schema) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:schema) :: String.t
        defp unquote(parser.method)(:schema), do: unquote(schema)
      end
    ])
    |> Parser.match(Map.delete(spec, "$schema"))
  end

  @spec set_id(Parser.t, map, String.t) :: Parser.t
  def set_id(parser, spec, id) do
    parser
    |> Annotate.public
    |> Parser.append_blocks([
      quote do
        @spec unquote(parser.method)(:id) :: String.t
        defp unquote(parser.method)(:id), do: unquote(id)
      end
    ])
    |> Parser.match(Map.delete(spec, "$id"))
  end

end
