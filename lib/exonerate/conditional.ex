defmodule Exonerate.Conditional do

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  alias Exonerate.Method
  alias Exonerate.Parser

  @spec match(json, Parser.t, atom) :: Parser.t
  def match(spec = %{"if" => testspec}, parser, method) do

    test_child = Method.concat(method, "if")
    then_child = Method.concat(method, "then")
    else_child = Method.concat(method, "else")
    base_child = Method.concat(method, "_base")

    {then_ast, then_dep} = ast_and_deps(spec["then"], then_child)
    {else_ast, else_dep} = ast_and_deps(spec["else"], else_child)

    basespec = Map.drop(spec, ["if", "then", "else"])

    new_parser = struct!(Exonerate.Parser)

    test_dep = Parser.match(testspec, new_parser, test_child)
    base_dep = Parser.match(basespec, new_parser, base_child)

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

  @spec ast_and_deps(json | nil, atom) :: [Parser.t]

  defp ast_and_deps(nil, _), do: {:ok, []}
  defp ast_and_deps(spec, name) do
    {
      quote do
        unquote(name)(val)
      end,
      [Parser.match(spec, struct!(Exonerate.Parser), name)]
    }
  end

end
