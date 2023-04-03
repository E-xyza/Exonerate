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
      assert "/oneOf" = list[:absolute_keyword_location]

      assert [
               {:error,
                [
                  error_value: "foobarbaz",
                  instance_location: "/",
                  absolute_keyword_location: "/oneOf/2/type"
                ]},
               {:error,
                [
                  error_value: "foobarbaz",
                  instance_location: "/",
                  absolute_keyword_location: "/oneOf/1/type"
                ]},
               {:error,
                [
                  error_value: "foobarbaz",
                  instance_location: "/",
                  absolute_keyword_location: "/oneOf/0/type"
                ]}
             ] = list[:errors]

      assert "no matches" == list[:reason]
    end

    test "reports multiple matches" do
      assert {:error, list} = one_of(15)
      assert "/oneOf" = list[:absolute_keyword_location]

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
      assert "/anyOf" = list[:absolute_keyword_location]

      assert [
               {:error,
                [
                  error_value: "foobarbaz",
                  instance_location: "/",
                  absolute_keyword_location: "/anyOf/1/type"
                ]},
               {:error,
                [
                  error_value: "foobarbaz",
                  instance_location: "/",
                  absolute_keyword_location: "/anyOf/0/maxLength"
                ]}
             ] = list[:errors]
    end
  end
end
