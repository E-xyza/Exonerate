defmodule ExonerateTest.Tutorial.BooleanTest do
  use ExUnit.Case, async: true

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/boolean.html

  Literally conforms to all the tests presented in this document.
  """

  @moduletag :tutorial

  defmodule Boolean do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/boolean.html#boolean
    """

    require Exonerate
    Exonerate.function_from_string(:def, :boolean, ~s({ "type": "boolean" }))
  end

  describe "the boolean test" do
    test "only matches true bools" do
      assert :ok = Boolean.boolean(true)
      assert :ok = Boolean.boolean(false)
    end
    test "doesn't match not quite bools" do
      assert  {:error, _} = Boolean.boolean("true")

      assert  {:error, _} = Boolean.boolean(0)
    end
  end
end
