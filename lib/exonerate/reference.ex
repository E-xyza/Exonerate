defmodule Exonerate.Reference do

  alias Exonerate.Annotate
  alias Exonerate.Method
  alias Exonerate.Parser

  @spec match(Parser.t, String.t)::Parser.t
  def match(parser, ref) do

    called_method = parser.method
    |> Method.root
    |> Method.jsonpath_to_method(ref)

    parser
    |> Annotate.impl
    |> Annotate.req(called_method)
    |> Parser.append_blocks([
      quote do
        defp unquote(parser.method)(val) do
          unquote(called_method)(val)
        end
      end
    ])
  end
end
