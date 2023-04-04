# bootstraps content for the readme tests

readme = Path.join(__DIR__, "../../README.md")

[module, tests] =
  readme
  |> File.read!()
  |> String.split("```elixir")
  |> Enum.map(&hd(String.split(&1, "```")))
  |> Enum.slice(2..-1)

Code.eval_string(module)

defmodule ExonerateTest.Readme do
  @external_resource readme
  @moduledoc tests
end
