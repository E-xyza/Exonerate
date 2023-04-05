defmodule Benchmark.Schema do
  alias Benchmark.Test

  @enforce_keys [:group, :description, :schema, :tests]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          group: String.t(),
          description: String.t(),
          schema: Exonerate.Type.json(),
          tests: Test.t()
        }

  def stream_from_directory(directory, opts \\ []) do
    directory
    |> File.ls!()
    |> Stream.reject(&(Path.extname(&1) != ".json"))
    |> Stream.reject(&omitted_file?(&1, opts))
    |> Stream.filter(&only_file?(&1, opts))
    |> Stream.flat_map(fn filename ->
      directory
      |> Path.join(filename)
      |> File.read!()
      |> Jason.decode!()
      |> unpack_schemas(filename, opts)
    end)
  end

  defp unpack_schemas(schemas, filename, opts) do
    Enum.flat_map(schemas, fn schema ->
      description = schema["description"]

      List.wrap(
        unless omitted_schema?(description, opts) do
          %__MODULE__{
            group: Path.basename(filename, ".json"),
            description: description,
            schema: schema["schema"],
            tests: Test.unpack_tests(schema["tests"])
          }
        end
      )
    end)
  end

  defp only_file?(path, opts) do
    case Keyword.get(opts, :only) do
      nil ->
        true

      only ->
        Path.basename(path) in only
    end
  end

  defp omitted_file?(path, opts) do
    case Keyword.get(opts, :omit) do
      nil -> false
      omit -> Path.basename(path) in omit
    end
  end

  defp omitted_schema?(description, opts) do
    case Keyword.get(opts, :omit) do
      nil -> false
      omit -> description in omit
    end
  end
end
