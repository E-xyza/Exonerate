defmodule ExonerateTest.CodeCase do
  defmacro assert_filter(code, module, function, schema) do
    [
      quote do
        require unquote(module)
      end,
      quote bind_quoted: binding() do
        Exonerate.Cache.put_schema(__MODULE__, function, schema)

        ast =
          quote do
            unquote(module).filter(unquote(function), [], [])
          end

        assert Macro.to_string(code) ==
                 ast
                 |> Macro.expand_once(__ENV__)
                 |> Macro.to_string()
      end
    ]
  end
end
