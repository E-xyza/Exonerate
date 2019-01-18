defmodule ExonerateTest.Macro.Tutorial.CombiningTest do
  use ExUnit.Case, async: true

  @moduletag :generic

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
    import Exonerate.Macro

    defschema combining: """
    {
      "anyOf": [
        { "type": "string", "maxLength": 5 },
        { "type": "number", "minimum": 0 }
      ]
    }
    """
  end

  describe "anyOf combines schemas" do
    test "validating values match" do
      assert :ok == Combining.combining("short")
      assert :ok == Combining.combining(12)
    end

    test "things that match none don't match" do
      assert  {:mismatch,
      {ExonerateTest.Macro.Tutorial.CombiningTest.Combining,
      :combining, ["too long"]}}
      = Combining.combining("too long")

      assert  {:mismatch,
      {ExonerateTest.Macro.Tutorial.CombiningTest.Combining,
      :combining, [-5]}}
      = Combining.combining(-5)
    end
  end

end
