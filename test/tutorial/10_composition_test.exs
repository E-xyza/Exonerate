defmodule ExonerateTest.Tutorial.CompositionTest do
  use ExUnit.Case, async: true

  @moduletag :combining
  @moduletag :tutorial

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/combining.html
  Literally conforms to all the tests presented in this document.
  """

  defmodule Combining do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/combining.html#combining-schemas
    """
    require Exonerate

    Exonerate.function_from_string(
      :def,
      :combining,
      """
      {
        "anyOf": [
          { "type": "string", "maxLength": 5 },
          { "type": "number", "minimum": 0 }
        ]
      }
      """
    )
  end

  describe "combining schemas is possible" do
    test "validating values match" do
      assert :ok == Combining.combining("short")
      assert :ok == Combining.combining(12)
    end

    test "things that match none don't match" do
      assert {:error, list} = Combining.combining("too long")

      assert list[:schema_pointer] == "/anyOf"
      assert list[:error_value] == "too long"
      assert list[:json_pointer] == "/"

      assert {:error, list} = Combining.combining(-5)

      assert list[:schema_pointer] == "/anyOf"
      assert list[:error_value] == -5
      assert list[:json_pointer] == "/"
    end
  end

  #  defmodule AllOf do
  #    @moduledoc """
  #    tests from:
  #
  #    https://json-schema.org/understanding-json-schema/reference/combining.html#allof
  #    """
  #    require Exonerate
  #
  #    Exonerate.function_from_string(
  #      :def,
  #      :allof,
  #      """
  #      {
  #        "allOf": [
  #          { "type": "string" },
  #          { "maxLength": 5 }
  #        ]
  #      }
  #      """
  #    )
  #
  #    Exonerate.function_from_string(:def, :impossible, """
  #    {
  #      "allOf": [
  #        { "type": "string" },
  #        { "type": "number" }
  #      ]
  #    }
  #    """)
  #  end
  #
  #  describe "allOf combines schemas" do
  #    test "validating values match" do
  #      assert :ok == AllOf.allof("short")
  #    end
  #
  #    test "things that mismatch one don't match" do
  #      assert {:error, list} = AllOf.allof("too long")
  #
  #      assert list[:schema_pointer] == "/allOf/1/maxLength"
  #      assert list[:error_value] == "too long"
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
  #
  #  describe "logical impossibilities" do
  #    test "are possible of allof" do
  #      assert {:error, list} = AllOf.impossible("No way")
  #
  #      assert list[:schema_pointer] == "/allOf/1/type"
  #      assert list[:error_value] == "No way"
  #      assert list[:json_pointer] == "/"
  #
  #      assert {:error, list} = AllOf.impossible(-1)
  #
  #      assert list[:schema_pointer] == "/allOf/0/type"
  #      assert list[:error_value] == -1
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
  #
  #  defmodule AnyOf do
  #    @moduledoc """
  #    tests from:
  #
  #    https://json-schema.org/understanding-json-schema/reference/combining.html#anyof
  #    """
  #    require Exonerate
  #
  #    Exonerate.function_from_string(:def, :anyof, """
  #    {
  #      "anyOf": [
  #        { "type": "string" },
  #        { "type": "number" }
  #      ]
  #    }
  #    """)
  #  end
  #
  #  describe "anyOf combines schemas" do
  #    test "validating values match" do
  #      assert :ok == AnyOf.anyof("yes")
  #      assert :ok == AnyOf.anyof(42)
  #    end
  #
  #    test "things that mismatch one don't match" do
  #      assert {:error, list} = AnyOf.anyof(%{"Not a" => "string or number"})
  #
  #      assert list[:schema_pointer] == "/anyOf"
  #      assert list[:error_value] == %{"Not a" => "string or number"}
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
  #
  #  defmodule OneOf do
  #    @moduledoc """
  #    tests from:
  #
  #    https://json-schema.org/understanding-json-schema/reference/combining.html#oneof
  #    """
  #    require Exonerate
  #
  #    Exonerate.function_from_string(:def, :oneof, """
  #    {
  #      "oneOf": [
  #        { "type": "number", "multipleOf": 5 },
  #        { "type": "number", "multipleOf": 3 }
  #      ]
  #    }
  #    """)
  #
  #    Exonerate.function_from_string(:def, :factorout, """
  #    {
  #      "type": "number",
  #      "oneOf": [
  #        { "multipleOf": 5 },
  #        { "multipleOf": 3 }
  #      ]
  #    }
  #    """)
  #  end
  #
  #  describe "oneOf combines schemas" do
  #    test "multiples of 3 or 5 work" do
  #      assert :ok == OneOf.oneof(10)
  #      assert :ok == OneOf.oneof(9)
  #    end
  #
  #    test "multiples of neither don't" do
  #      assert {:error, list} = OneOf.oneof(2)
  #
  #      assert list[:schema_pointer] == "/oneOf"
  #      assert list[:error_value] == 2
  #      assert list[:json_pointer] == "/"
  #    end
  #
  #    test "multiples of both don't" do
  #      assert {:error, list} = OneOf.oneof(15)
  #
  #      assert list[:schema_pointer] == "/oneOf"
  #      assert list[:error_value] == 15
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
  #
  #  describe "things can be factored out" do
  #    test "multiples of 3 or 5 work" do
  #      assert :ok == OneOf.factorout(10)
  #      assert :ok == OneOf.factorout(9)
  #    end
  #
  #    test "multiples of neither don't" do
  #      assert {:error, list} = OneOf.factorout(2)
  #
  #      assert list[:schema_pointer] == "/oneOf"
  #      assert list[:error_value] == 2
  #      assert list[:json_pointer] == "/"
  #    end
  #
  #    test "multiples of both don't" do
  #      assert {:error, list} = OneOf.factorout(15)
  #
  #      assert list[:schema_pointer] == "/oneOf"
  #      assert list[:error_value] == 15
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
  #
  #  defmodule Not do
  #    @moduledoc """
  #    tests from:
  #
  #    https://json-schema.org/understanding-json-schema/reference/combining.html#not
  #    """
  #    require Exonerate
  #
  #    Exonerate.function_from_string(:def, :no, """
  #    { "not": { "type": "string" } }
  #    """)
  #  end
  #
  #  describe "not inverts schemas" do
  #    test "validating values match" do
  #      assert :ok == Not.no(42)
  #      assert :ok == Not.no(%{"key" => "value"})
  #    end
  #
  #    test "things that mismatch one don't match" do
  #      assert {:error, list} = Not.no("I am a string")
  #
  #      assert list[:schema_pointer] == "/not"
  #      assert list[:error_value] == "I am a string"
  #      assert list[:json_pointer] == "/"
  #    end
  #  end
end
