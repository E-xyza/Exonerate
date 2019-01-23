defmodule ExonerateTest.Tutorial.CombiningTest do
  use ExUnit.Case, async: true

  @moduletag :one #:combining

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
    import Exonerate

    defschema combining: """
    {
      "anyOf": [
        { "type": "string", "maxLength": 5 },
        { "type": "number", "minimum": 0 }
      ]
    }
    """
  end

  describe "combiningn schemas is possible" do
    test "validating values match" do
      assert :ok == Combining.combining("short")
      assert :ok == Combining.combining(12)
    end

    test "things that match none don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.Combining,
      :combining, ["too long"]}}
      = Combining.combining("too long")

      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.Combining,
      :combining, [-5]}}
      = Combining.combining(-5)
    end
  end

  defmodule AllOf do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/combining.html#allof
    """
    import Exonerate

    defschema allof: """
    {
      "allOf": [
        { "type": "string" },
        { "maxLength": 5 }
      ]
    }
    """

    defschema impossible: """
    {
      "allOf": [
        { "type": "string" },
        { "type": "number" }
      ]
    }
    """
  end

  describe "allOf combines schemas" do
    test "validating values match" do
      assert :ok == AllOf.allof("short")
    end

    test "things that mismatch one don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.AllOf,
      :allof, ["too long"]}}
      = AllOf.allof("too long")
    end
  end

  describe "logical impossibilities" do
    test "are possible of allof" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.AllOf,
      :impossible, ["No way"]}}
      = AllOf.impossible("No way")

      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.AllOf,
      :impossible, [-1]}}
      = AllOf.impossible(-1)
    end
  end

  defmodule AnyOf do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/combining.html#anyof
    """
    import Exonerate

    defschema anyof: """
    {
      "anyOf": [
        { "type": "string" },
        { "type": "number" }
      ]
    }
    """
  end

  describe "anyOf combines schemas" do
    test "validating values match" do
      assert :ok == AnyOf.anyof("yes")
      assert :ok == AnyOf.anyof(42)
    end

    test "things that mismatch one don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.AnyOf,
      :anyof, [%{"Not a" => "string or number"}]}}
      = AnyOf.anyof(%{"Not a" => "string or number"})
    end
  end

  defmodule OneOf do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/combining.html#oneof
    """
    import Exonerate

    defschema oneof: """
    {
      "oneOf": [
        { "type": "number", "multipleOf": 5 },
        { "type": "number", "multipleOf": 3 }
      ]
    }
    """

    defschema factorout: """
    {
      "type": "number",
      "oneOf": [
        { "multipleOf": 5 },
        { "multipleOf": 3 }
      ]
    }
    """
  end

  describe "oneOf combines schemas" do
    test "multiples of 3 or 5 work" do
      assert :ok == OneOf.oneof(10)
      assert :ok == OneOf.oneof(9)
    end

    test "multiples of neither don't" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.OneOf,
      :oneof, [2]}}
      = OneOf.oneof(2)
    end

    test "multiples of both don't" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.OneOf,
      :oneof, [15]}}
      = OneOf.oneof(15)
    end
  end

  describe "things can be factored out" do
    test "multiples of 3 or 5 work" do
      assert :ok == OneOf.factorout(10)
      assert :ok == OneOf.factorout(9)
    end

    test "multiples of neither don't" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.OneOf,
      :factorout, [2]}}
      = OneOf.factorout(2)
    end

    test "multiples of both don't" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.OneOf,
      :factorout, [15]}}
      = OneOf.factorout(15)
    end
  end


  defmodule Not do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/combining.html#not
    """
    import Exonerate

    defschema no: """
    { "not": { "type": "string" } }
    """
  end

  describe "not inverts schemas" do
    test "validating values match" do
      assert :ok == Not.no(42)
      assert :ok == Not.no(%{"key" => "value"})
    end

    test "things that mismatch one don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.CombiningTest.Not,
      :no___not, ["I am a string"]}}
      = Not.no("I am a string")
    end
  end

end
