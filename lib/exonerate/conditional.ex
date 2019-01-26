defmodule Exonerate.Conditional do

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  alias Exonerate.Method

  @spec match(json, atom) :: [defblock]
  def match(spec = %{"if" => testspec}, method) do

    test_child = Method.concat(method, "_if")
    then_child = Method.concat(method, "_then")
    else_child = Method.concat(method, "_else")
    base_child = Method.concat(method, "__base")

    {then_ast, then_deps} = ast_and_deps(spec["then"], then_child)
    {else_ast, else_deps} = ast_and_deps(spec["else"], else_child)

    basespec = Map.drop(spec, ["if", "then", "else"])

    [quote do
      def unquote(method)(val) do
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
    end] ++
    Exonerate.matcher(testspec, test_child) ++
    then_deps ++
    else_deps ++
    Exonerate.matcher(basespec, base_child)
  end

  defp ast_and_deps(nil, _), do: {:ok, []}
  defp ast_and_deps(spec, name) do
    {
      quote do
        unquote(name)(val)
      end,
      Exonerate.matcher(spec, name)
    }
  end

end
