defmodule ExonerateTest.Tutorial.BooleanTest do
  use ExUnit.Case, async: true

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/boolean.html

  Literally conforms to all the tests presented in this document.
  """
  defmodule Boolean do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/boolean.html#boolean
    """
    import Exonerate

    defschema boolean: ~s({ "type": "boolean" })
  end

  describe "the boolean test" do
    test "only matches true bools" do
      assert :ok = Boolean.boolean(true)
      assert :ok = Boolean.boolean(false)
    end
    test "doesn't match not quite bools" do
      assert  {:mismatch, {"#", "true"}} == Boolean.boolean("true")

      assert  {:mismatch, {"#", 0}} == Boolean.boolean(0)
    end
  end
end
