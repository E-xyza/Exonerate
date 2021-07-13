defmodule ExonerateTest.Docs do
  require Exonerate

  @doc "test doc"
  Exonerate.function_from_string(:def, :foo, "{}")
end
