defmodule Exonerate.Bowtie.Harness do
  @moduledoc """
  Bowtie test harness for Exonerate.

  Implements the IHOP protocol to allow Exonerate to participate in
  Bowtie's JSON Schema compliance testing.

  See: https://docs.bowtie.report/en/stable/implementers/
  """

  alias Exonerate.Bowtie.Runner

  @json if Code.ensure_loaded?(JSON) and function_exported?(JSON, :decode, 1), do: JSON, else: @json

  @version 1

  @doc """
  Main entry point for the harness. Reads commands from stdin and
  writes responses to stdout.
  """
  def main(_args \\ []) do
    # Ensure line buffering on stdout
    :io.setopts(:standard_io, [:binary, :utf8])

    loop(%{dialect: nil})
  end

  defp loop(state) do
    case IO.read(:stdio, :line) do
      :eof ->
        :ok

      {:error, reason} ->
        IO.puts(:stderr, "Error reading input: #{inspect(reason)}")
        :ok

      line ->
        line
        |> String.trim()
        |> handle_line(state)
        |> case do
          {:continue, new_state} ->
            loop(new_state)

          :stop ->
            :ok
        end
    end
  end

  defp handle_line("", state), do: {:continue, state}

  defp handle_line(line, state) do
    case @json.decode(line) do
      {:ok, command} ->
        handle_command(command, state)

      {:error, reason} ->
        IO.puts(:stderr, "@json parse error: #{inspect(reason)}")
        {:continue, state}
    end
  end

  defp handle_command(%{"cmd" => "start", "version" => 1}, state) do
    response = %{
      version: @version,
      implementation: %{
        language: "elixir",
        name: "exonerate",
        version: exonerate_version(),
        homepage: "https://github.com/E-xyza/Exonerate",
        issues: "https://github.com/E-xyza/Exonerate/issues",
        source: "https://github.com/E-xyza/Exonerate",
        dialects: supported_dialects()
      }
    }

    write_response(response)
    {:continue, state}
  end

  defp handle_command(%{"cmd" => "dialect", "dialect" => dialect}, state) do
    # Check if we support this dialect
    supported = dialect in supported_dialects()
    write_response(%{ok: supported})
    {:continue, %{state | dialect: if(supported, do: dialect, else: state.dialect)}}
  end

  defp handle_command(%{"cmd" => "run", "seq" => seq, "case" => test_case}, state) do
    response = run_test_case(seq, test_case, state)
    write_response(response)
    {:continue, state}
  end

  defp handle_command(%{"cmd" => "stop"}, _state) do
    :stop
  end

  defp handle_command(unknown, state) do
    IO.puts(:stderr, "Unknown command: #{inspect(unknown)}")
    {:continue, state}
  end

  defp run_test_case(seq, test_case, state) do
    schema = test_case["schema"]
    tests = test_case["tests"]
    registry = Map.get(test_case, "registry", %{})

    try do
      results = Runner.run(schema, tests, registry, state.dialect)
      %{seq: seq, results: results}
    rescue
      e ->
        %{
          seq: seq,
          errored: true,
          context: %{
            message: Exception.message(e),
            traceback: Exception.format(:error, e, __STACKTRACE__)
          }
        }
    catch
      kind, reason ->
        %{
          seq: seq,
          errored: true,
          context: %{
            message: "#{kind}: #{inspect(reason)}",
            traceback: ""
          }
        }
    end
  end

  defp write_response(response) do
    IO.puts(@json.encode!(response))
  end

  defp exonerate_version do
    case :application.get_key(:exonerate, :vsn) do
      {:ok, version} -> List.to_string(version)
      _ -> "unknown"
    end
  end

  defp supported_dialects do
    [
      "https://json-schema.org/draft/2020-12/schema",
      "https://json-schema.org/draft/2019-09/schema",
      "http://json-schema.org/draft-07/schema#",
      "http://json-schema.org/draft-06/schema#",
      "http://json-schema.org/draft-04/schema#"
    ]
  end
end
