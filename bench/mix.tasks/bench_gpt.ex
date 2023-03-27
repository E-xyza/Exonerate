defmodule Mix.Tasks.BenchGpt do
  @shortdoc "benchmark against GPT variants"
  use Mix.Task

  def run(_) do
    Application.ensure_all_started(:req)
    # retrieve schema content from GPT-3
    schema = Benchmark.GPT.fetch_schema_code!(~s({"type": "string", "maxLength": 10}))
  end
end
