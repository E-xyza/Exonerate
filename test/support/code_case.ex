defmodule ExonerateTest.CodeCase do
  defmacro assert_filter(code, module, function, schema, opts \\ []) do
    root = Keyword.get(opts, :root, [])
    resource = "function://#{function}/"

    [
      quote do
        require unquote(module)
      end,
      quote bind_quoted: binding() do
        Exonerate.Cache.put_schema(__MODULE__, resource, schema)

        ast =
          quote do
            unquote(module).filter(unquote(resource), unquote(root), unquote(opts))
          end

        assert Macro.to_string(code) ==
                 ast
                 |> Macro.expand_once(__ENV__)
                 |> ExonerateTest.Tools.find_first_defp()
                 |> Macro.to_string()
      end
    ]
  end
end
