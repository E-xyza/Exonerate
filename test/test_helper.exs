includes =
  ExUnit.configuration()
  |> Keyword.get(:include)
  |> Enum.map(fn atom ->
    atom
    |> Atom.to_string()
    |> Path.basename()
    |> String.to_atom()
  end)

Bandit.start_link(plug: ExonerateTest.FilePlug, scheme: :http, options: [port: 1234])

ExUnit.configuration()
|> Keyword.put(:include, includes)
|> ExUnit.start()
