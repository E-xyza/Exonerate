defmodule ExonerateTest.EntryPointTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(:def, :entrypoint, """
  {
    "$defs": {
      "string": {"type": "string"},
      "number": {"type": "number"}
    },
    "schema": {
      "anyOf": [
        {"$ref": "#/$defs/string"},
        {"$ref": "#/$defs/number"}
      ]
    }
  }
  """, entrypoint: "/schema")

  test "entrypoints inside the schema" do
    assert :ok == entrypoint(1234)
    assert :ok == entrypoint("foobar")
    assert {:error, _} = entrypoint(%{})
    assert {:error, _} = entrypoint([])
  end
end
