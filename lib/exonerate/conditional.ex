defmodule Exonerate.Conditional do

  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type ast      :: Parser.ast
  @type specmap  :: Exonerate.specmap

  @spec match(json, Parser.t, atom) :: Parser.t
  def match(parser, spec = %{"if" => testspec}, method) do

    test_child = Method.concat(method, "if")
    then_child = Method.concat(method, "then")
    else_child = Method.concat(method, "else")
    base_child = Method.concat(method, "_base")

    {then_ast, then_dep} = ast_and_deps(spec["then"], then_child)
    {else_ast, else_dep} = ast_and_deps(spec["else"], else_child)

    basespec = Map.drop(spec, ["if", "then", "else"])

    new_parser = struct!(Exonerate.Parser)

    test_dep = Parser.match(new_parser, testspec, test_child)
    base_dep = Parser.match(new_parser, basespec, base_child)

    parser
    |> Parser.add_dependencies(then_dep ++ else_dep ++ [test_dep, base_dep])
    |> Parser.append_blocks([quote do
      defp unquote(method)(val) do
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
      [Parser.match(struct!(Exonerate.Parser), spec, name)]
    }
  end

end
