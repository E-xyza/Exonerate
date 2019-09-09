defmodule Exonerate.MatchString do

  alias Exonerate.BuildCond
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec match(Parser.t, specmap, boolean) :: Parser.t
  def match(parser, spec, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(parser.method)
    |> BuildCond.build

    length_stmt = if (Map.has_key?(spec, "maxLength") ||
                      Map.has_key?(spec, "minLength") ) do
      quote do
        length = String.length(val)
      end
    else
      nil
    end

    str_match = quote do
      defp unquote(parser.method)(val) when is_binary(val) do
        unquote(length_stmt)
        unquote(cond_stmt)
      end
    end

    parser
    |> Parser.append_block(str_match)
    |> Parser.never_matches(terminal)
  end

  @spec build_cond(specmap, atom) :: [BuildCond.condclause]
  defp build_cond(spec = %{"maxLength" => length}, method) do
    [
      {
        quote do length > unquote(length) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maxLength")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"minLength" => length}, method) do
    [
      {
        quote do length < unquote(length) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minLength")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"pattern" => patt}, method) do
    [
      {
        quote do !(Regex.match?(sigil_r(<<unquote(patt)>>, ''), val)) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("pattern")
      |> build_cond(method)
    ]
  end
  defp build_cond(_spec, _method), do: []

end
