defmodule ExonerateTest.Tutorial.NumericTest do
  use ExUnit.Case, async: true

  @moduletag :numeric

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/numeric.html
  Literally conforms to all the tests presented in this document.
  """

  defmodule Integer do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/numeric.html#integer

    NOTE: the elixir version is opinionated about accepting multiples for non-integer
    types and does not implement them for floating points.
    """
    import Exonerate

    defschema integer: ~s({ "type": "integer" })
  end

  describe "basic integers example" do
    test "various integers match correctly" do
      assert :ok = Integer.integer(42)
      assert :ok = Integer.integer(-1)
    end

    test "integer mismatches a float or string" do
      assert {:mismatch, {"#", 3.1415926}} == Integer.integer(3.1415926)
      assert {:mismatch, {"#", "42"}} == Integer.integer("42")
    end
  end

  defmodule Number do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/numeric.html#number

    """
    import Exonerate

    defschema number: ~s({ "type": "number" })
  end

  describe "basic numbers example" do
    test "various numbers match correctly" do
      assert :ok = Number.number(42)
      assert :ok = Number.number(-1)
      assert :ok = Number.number(5.0)
      assert :ok = "2.99792458e8" |> Jason.decode! |> Number.number
    end

    test "number mismatches a string" do
      assert {:mismatch, {"#", "42"}} = Number.number("42")
    end
  end

  defmodule Multiple do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/numeric.html#muliples

    NOTE: the elixir version is opinionated about accepting multiples for non-integer
    types and does not implement them for floating points.
    """
    import Exonerate

    defschema integer: ~s({ "type": "integer", "multipleOf": 10 })
  end

  describe "basic multiples example" do
    test "various multiples match correctly" do
      assert :ok = Multiple.integer(0)
      assert :ok = Multiple.integer(10)
      assert :ok = Multiple.integer(20)
    end

    test "multiple mismatches noninteger" do
      assert {:mismatch, {"#", 23}} = Multiple.integer(23)
    end
  end

  defmodule Range do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/numeric.html#range

    """
    import Exonerate

    defschema number: """
                      {
                        "type": "number",
                        "minimum": 0,
                        "exclusiveMaximum": 100
                      }
                      """
  end

  describe "basic ranging example" do
    test "interior values match correctly" do
      assert :ok = Range.number(0)   #note inclusive minimum.
      assert :ok = Range.number(10)
      assert :ok = Range.number(99)
    end

    test "multiple mismatches noninteger" do
      assert {:mismatch, {"#", -1}} = Range.number(-1)
      assert {:mismatch, {"#", 100}} = Range.number(100)  #exclusive maximum
      assert {:mismatch, {"#", 101}} = Range.number(101)
    end
  end

end
