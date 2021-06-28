includes = ExUnit.configuration()
|> Keyword.get(:include)
|> Enum.map(fn atom ->
  atom
  |> Atom.to_string
  |> Path.basename
  |> String.to_atom
end)

ExUnit.configuration()
|> Keyword.put(:include, includes)
|> ExUnit.start()
