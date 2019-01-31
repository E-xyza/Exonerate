defmodule Exonerate.Reference do

  alias Exonerate.Annotate
  alias Exonerate.Method
  alias Exonerate.Parser

  @spec match(String.t, Parser.t, atom)::Parser.t
  def match(ref, parser, method) do

    called_method = method
    |> Method.root
    |> Method.jsonpath_to_method(ref)

    parser
    |> Annotate.impl(method)
    |> Annotate.req(called_method)
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          unquote(called_method)(val)
        end
      end
    ])
  end
end
