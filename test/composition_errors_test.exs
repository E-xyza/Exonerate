defmodule ExonerateTest.CompositionTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(:defp, :one_of, """
  {
    "oneOf": [
      { "type": "number", "multipleOf": 5 },
      { "type": "number", "multipleOf": 3 },
      { "type": "object" }
    ]
  }
  """)

  describe "oneOf" do
    test "reports failures when there are multiple failures" do
      assert {:error, list} = one_of("foobarbaz")
      assert "/oneOf" = list[:schema_pointer]
      assert [[
        schema_pointer: "/oneOf/0/type",
        error_value: "foobarbaz",
        json_pointer: "/"
      ],[
        schema_pointer: "/oneOf/1/type",
        error_value: "foobarbaz",
        json_pointer: "/"
      ],[
        schema_pointer: "/oneOf/2/type",
        error_value: "foobarbaz",
        json_pointer: "/"
      ]] = list[:failures]

      assert "no matches" == list[:reason]
    end

    test "reports multiple failures" do
      assert {:error, list} = one_of(15)
      assert "/oneOf" = list[:schema_pointer]
      assert [[
        schema_pointer: "/oneOf/2/type",
        error_value: 15,
        json_pointer: "/"
      ]] = list[:failures]

      assert ["/oneOf/0", "/oneOf/1"] == list[:matches]

      assert "multiple matches" == list[:reason]
    end
  end

  Exonerate.function_from_string(:defp, :any_of, """
  {
    "anyOf": [
      { "type": "string", "maxLength": 5 },
      { "type": "number", "minimum": 0 }
    ]
  }
  """)

  describe "anyOf" do
    test "reports all failures when there are multiple failures" do
      assert {:error, list} = any_of("foobarbaz")
      assert "/anyOf" = list[:schema_pointer]
      assert [[
        schema_pointer: "/anyOf/0/maxLength",
        error_value: "foobarbaz",
        json_pointer: "/"
      ],[
        schema_pointer: "/anyOf/1/type",
        error_value: "foobarbaz",
        json_pointer: "/"
      ]] = list[:failures]
    end
  end
end
