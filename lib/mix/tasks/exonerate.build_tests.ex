defmodule Mix.Tasks.Exonerate.BuildTests do
  use Mix.Task
  require Logger

  @testdir "test/JSON-Schema-Test-Suite/tests/draft7"
  @destdir "test/automated"
  @ignore ["definitions.json", "if-then-else.json", "ref.json", "refRemote.json"]
  #@only ["anyOf.json"]
  @banned %{"multipleOf" => ["by number", "by small number"]}

  def run(_) do
    File.rm_rf!(@destdir)
    File.mkdir_p!(@destdir)
    @testdir
    |> File.ls!
    |> Enum.reject(&(&1 in @ignore))
    #|> Enum.filter(&(&1 in @only))
    |> Enum.reject(&(File.dir?(testdir(&1))))
    |> Stream.map(&{Path.basename(&1, ".json"), testdir(&1)})
    |> Stream.map(&json_to_exmap/1)
    |> Stream.map(&exmap_to_macro/1)
    |> Stream.map(fn {t, m} -> {t, Macro.to_string(m, &ast_xform/2)} end)
    |> Stream.map(fn
      {t, m} -> {t, Code.format_string!(m, locals_without_parens: [defschema: :*])}
    end)
    |> Enum.map(&send_to_file/1)
  end

  def send_to_file({title, m}) do
    title
    |> destdir
    |> File.write!(m)
  end

  @noparen [:defmodule, :use, :describe, :test, :defschema, :import, :assert]

  @spec ast_xform({atom, any, any}, String.t) :: String.t
  def ast_xform({atom, _, _}, str) when atom in @noparen do
    [head | rest] = String.split(str, "\n")
    parts = Regex.named_captures(~r/\((?<title>.*)\)(?<rest>.*)/, head)
    Atom.to_string(atom) <>
    " " <> parts["title"] <>
    parts["rest"] <> "\n" <> Enum.join(rest, "\n")
  end
  def ast_xform(_, str), do: str

  def testdir(v), do: Path.join(@testdir, v)
  def destdir(v), do: Path.join(@destdir, Path.basename(v, ".json") <> "_test.exs")

  def json_to_exmap({title, jsonfile}) do
    {title,
     jsonfile
     |> File.read!
     |> Jason.decode!}
  end

  def atom_to_module(m), do: Module.concat([m])

  def exmap_to_macro({title, testlist}) do

    modulename = title
    |> String.capitalize
    |> Kernel.<>("Test")
    |> String.to_atom
    |> atom_to_module

    schemas = testlist
    |> Enum.with_index
    |> Enum.map(&module_code/1)

    descriptions = testlist
    |> Enum.reject(&filter_banned(title, &1))
    |> Enum.with_index
    |> Enum.map(&description_code/1)

    {title,
    quote do
      defmodule unquote(modulename) do
        use ExUnit.Case, async: true

        defmodule Schemas do
          import Exonerate.Macro
          unquote_splicing(schemas)
        end

        unquote_splicing(descriptions)
      end
    end}
  end

  def module_code({description_map, index}) do

    schema_atom = String.to_atom("schema#{index}")

    schema_content = description_map
    |> Map.get("schema")
    |> Jason.encode!

    quote do
      defschema [{unquote(schema_atom), unquote(schema_content)}]
    end
  end

  def description_code({description_map, index}) do
    description_title = description_map["description"]
    tests = Enum.map(description_map["tests"], &test_code(&1, index))

    quote do
      describe unquote(description_title) do
        unquote_splicing(tests)
      end
    end
  end

  def test_code(test_map, index) do
    test_title = test_map["description"]
    test_data = test_map
    |> Map.get("data")
    |> Macro.escape
    schema_name = String.to_atom("schema#{index}")

    if test_map["valid"] do
      quote do
        test unquote(test_title) do
          assert :ok = Schemas.unquote(schema_name)(unquote(test_data))
        end
      end
    else
      quote do
        test unquote(test_title) do
          assert {:mismatch, _} = Schemas.unquote(schema_name)(unquote(test_data))
        end
      end
    end
  end

  def filter_banned(title, description) do
    @banned[title] && description["description"] in @banned[title]
  end
end
