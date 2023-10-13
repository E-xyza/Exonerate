defmodule ExonerateTest.Regression.NestedStringTypeTest do
  use ExUnit.Case, async: true
  require Exonerate

  # contributed by @ahacking (issue #78).  This is due to 
  # degeneracy testing across jumps in the schema not respecting
  # type being a single string instead of an array.

  Exonerate.function_from_string(:def, :validate_api, ~S"""
  {
      "$schema": "http://json-schema.org/draft-04/schema#",
      "title": "JSON validation failure",
      "type": "object",
      "id": "https://example.com/fail.json",
      "definitions": {
          "versionType": {
              "type": "string",
              "enum": [ "1.0", "1.1", "2.0" ]
          }
      },
      "properties": {
          "version": { "$ref": "#/definitions/versionType" }
      },
      "required": [ "version" ]
  }
  """)

  test "regression passes" do
    assert :ok = validate_api(%{"version" => "1.1"} )
  end
end
