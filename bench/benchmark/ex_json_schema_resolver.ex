defmodule Benchmark.ResolverHelper do
  def fetch!(file) do
    __DIR__
    |> Path.join("../../test/_draft7/remotes")
    |> Path.join(file)
    |> File.read!()
    |> Jason.decode!()
  end
end

defmodule Benchmark.ExJsonSchemaResolver do
  alias Benchmark.ResolverHelper
  @integer ResolverHelper.fetch!("integer.json")
  @sub_schemas ResolverHelper.fetch!("subSchemas.json")
  @folder_integer ResolverHelper.fetch!("baseUriChange/folderInteger.json")
  @folder_integer2 ResolverHelper.fetch!("baseUriChangeFolder/folderInteger.json")
  @folder_integer3 ResolverHelper.fetch!("baseUriChangeFolderInSubschema/folderInteger.json")
  @name ResolverHelper.fetch!("name.json")

  # remoterefs that are actually local refs (note no .json extension)!
  def resolve("http://localhost:1234/tree"), do: %{}
  def resolve("http://localhost:1234/node"), do: %{}
  def resolve("http://localhost:1234/integer.json"), do: @integer
  def resolve("http://localhost:1234/subSchemas.json"), do: @sub_schemas
  def resolve("http://localhost:1234/baseUriChange/folderInteger.json"), do: @folder_integer

  def resolve("http://localhost:1234/baseUriChangeFolder/folderInteger.json"),
    do: @folder_integer2

  def resolve("http://localhost:1234/baseUriChangeFolderInSubschema/folderInteger.json"),
    do: @folder_integer3

  def resolve("http://localhost:1234/name.json"), do: @name

  def resolve(unresolved) do
    raise "the following file is unresolved: #{unresolved}"
  end
end
