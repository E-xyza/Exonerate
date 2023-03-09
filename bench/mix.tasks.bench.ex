defmodule Mix.Tasks.Bench do
  use Mix.Task

  def run(_) do
    Benchmark.run()
  end
end
