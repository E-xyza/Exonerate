defmodule Mix.Tasks.Bowtie.Harness do
  @moduledoc """
  Runs the Bowtie test harness for Exonerate.

  This task implements the IHOP protocol, reading JSON commands from
  stdin and writing responses to stdout.

  ## Usage

      mix bowtie.harness

  This is primarily intended to be run inside a Docker container by
  Bowtie's test infrastructure.
  """

  use Mix.Task

  @shortdoc "Runs the Bowtie test harness"

  @impl Mix.Task
  def run(_args) do
    # Ensure the application is started
    Mix.Task.run("app.start")

    # Run the harness
    Exonerate.Bowtie.Harness.main()
  end
end
