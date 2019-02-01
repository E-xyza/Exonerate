defmodule Exonerate.Metadata do

  alias Exonerate.Annotate
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec set_title(Parser.t, specmap, String.t, atom) :: Parser.t
  def set_title(parser, spec, title, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:title) :: String.t
        defp unquote(method)(:title), do: unquote(title)
      end
    ])
    |> Parser.match(Map.delete(spec, "title"), method)
  end

  @spec set_description(Parser.t, specmap, String.t, atom) :: Parser.t
  def set_description(parser, spec, description, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:description) :: String.t
        defp unquote(method)(:description), do: unquote(description)
      end
    ])
    |> Parser.match(Map.delete(spec, "description"), method)
  end

  @spec set_default(Parser.t, specmap, json, atom) :: Parser.t
  def set_default(parser, spec, default, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:default) :: Exonerate.json
        defp unquote(method)(:default), do: unquote(default)
      end
    ])
    |> Parser.match(Map.delete(spec, "default"), method)
  end

  @spec set_examples(Parser.t, specmap, [json], atom) :: Parser.t
  def set_examples(parser, spec, examples, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:examples) :: [Exonerate.json]
        defp unquote(method)(:examples), do: unquote(examples)
      end
    ])
    |> Parser.match(Map.delete(spec, "examples"), method)
  end

  @spec set_schema(Parser.t, specmap, String.t, atom) :: Parser.t
  def set_schema(parser, spec, schema, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:schema) :: String.t
        defp unquote(method)(:schema), do: unquote(schema)
      end
    ])
    |> Parser.match(Map.delete(spec, "$schema"), method)
  end

  @spec set_id(Parser.t, map, String.t, atom) :: Parser.t
  def set_id(parser, spec, id, method) do
    parser
    |> Annotate.public(method)
    |> Parser.append_blocks([
      quote do
        @spec unquote(method)(:id) :: String.t
        defp unquote(method)(:id), do: unquote(id)
      end
    ])
    |> Parser.match(Map.delete(spec, "$id"), method)
  end

end
