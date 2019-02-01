defmodule Exonerate.Conditional do

  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type ast      :: Parser.ast
  @type specmap  :: Exonerate.specmap

  @spec match(Parser.t, json) :: Parser.t
  def match(parser, spec = %{"if" => testspec}) do

    test_child = Method.concat(parser, "if")
    then_child = Method.concat(parser, "then")
    else_child = Method.concat(parser, "else")
    base_child = Method.concat(parser, "_base")

    {then_ast, then_dep} = ast_and_deps(spec["then"], then_child)
    {else_ast, else_dep} = ast_and_deps(spec["else"], else_child)

    basespec = Map.drop(spec, ["if", "then", "else"])

    test_dep = Parser.new_match(testspec, test_child)
    base_dep = Parser.new_match(basespec, base_child)

    parser
    |> Parser.add_dependencies(then_dep ++ else_dep ++ [test_dep, base_dep])
    |> Parser.append_blocks([quote do
      defp unquote(parser.method)(val) do
        test_res = if :ok == unquote(test_child)(val) do
          unquote(then_ast)
        else
          unquote(else_ast)
        end

        if :ok == test_res do
          unquote(base_child)(val)
        else
          test_res
        end
      end
    end])
  end

  @spec ast_and_deps(json | nil, atom) :: {:ok | ast, [Parser.t]}

  defp ast_and_deps(nil, _), do: {:ok, []}
  defp ast_and_deps(spec, name) do
    {
      quote do
        unquote(name)(val)
      end,
      [Parser.new_match(spec, name)]
    }
  end

end
