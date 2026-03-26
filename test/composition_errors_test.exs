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
      assert "#/oneOf" = list[:absolute_keyword_location]

      errors = list[:errors]
      assert length(errors) == 3

      # Verify each error has the expected structure
      Enum.each(errors, fn {:error, err} ->
        assert err[:error_value] == "foobarbaz"
        assert err[:instance_location] == "/"
        assert err[:absolute_keyword_location] in ["#/oneOf/0/type", "#/oneOf/1/type", "#/oneOf/2/type"]
        assert err[:expected] != nil
      end)

      assert "no matches" == list[:reason]
    end

    test "reports multiple matches" do
      assert {:error, list} = one_of(15)
      assert "#/oneOf" = list[:absolute_keyword_location]

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
      assert "#/anyOf" = list[:absolute_keyword_location]

      errors = list[:errors]
      assert length(errors) == 2

      # One error is a type mismatch (anyOf/1 expects number)
      # One error is a maxLength violation (anyOf/0 accepts string but fails maxLength)
      type_error = Enum.find(errors, fn {:error, e} -> String.contains?(e[:absolute_keyword_location], "type") end)
      length_error = Enum.find(errors, fn {:error, e} -> String.contains?(e[:absolute_keyword_location], "maxLength") end)

      assert {:error, type_err} = type_error
      assert type_err[:error_value] == "foobarbaz"
      assert type_err[:expected] != nil

      assert {:error, length_err} = length_error
      assert length_err[:error_value] == "foobarbaz"
      refute length_err[:expected]  # maxLength error doesn't have expected type
    end
  end
end
