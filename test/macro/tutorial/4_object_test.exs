defmodule ExonerateTest.Macro.Tutorial.ObjectTest do
  use ExUnit.Case, async: true

  @moduletag :object

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/object.html
  Literally conforms to all the tests presented in this document.
  """

  defmodule Object do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#object

    """
    import Exonerate.Macro

    defschema object: ~s({ "type": "object" })
  end

  describe "basic objects example" do
    test "various objects match correctly" do
      assert :ok =
      """
      {
        "key"         : "value",
        "another_key" : "another_value"
      }
      """
      |> Jason.decode!
      |> Object.object

      assert :ok =
      """
      {
          "Sun"     : 1.9891e30,
          "Jupiter" : 1.8986e27,
          "Saturn"  : 5.6846e26,
          "Neptune" : 10.243e25,
          "Uranus"  : 8.6810e25,
          "Earth"   : 5.9736e24,
          "Venus"   : 4.8685e24,
          "Mars"    : 6.4185e23,
          "Mercury" : 3.3022e23,
          "Moon"    : 7.349e22,
          "Pluto"   : 1.25e22
      }
      """
      |> Jason.decode!
      |> Object.object
    end

    @badarray ["An", "array", "not", "an", "object"]

    test "objects mismatches a string or array" do
      assert {:mismatch, {ExonerateTest.Macro.Tutorial.ObjectTest.Object, :object, "Not an object"}} =
        Object.object("Not an object")

      assert {:mismatch, {ExonerateTest.Macro.Tutorial.ObjectTest.Object, :object, @badarray}} =
        Object.object(@badarray)
    end
  end

  defmodule Properties do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#properties

    """
    import Exonerate.Macro

    defschema address1: """
                        {
                          "type": "object",
                          "properties": {
                            "number":      { "type": "number" },
                            "street_name": { "type": "string" },
                            "street_type": { "type": "string",
                                             "enum": ["Street", "Avenue", "Boulevard"]
                                           }
                          }
                        }
                        """
  end

  @addr1 ~s({ "number": 1600, "street_name": "Pennsylvania", "street_type": "Avenue" })
  @addr2 ~s({ "number": "1600", "street_name": "Pennsylvania", "street_type": "Avenue" })
  @addr3 ~s({ "number": 1600, "street_name": "Pennsylvania" })
  @addr4 ~s({ "number": 1600, "street_name": "Pennsylvania", "street_type": "Avenue", "direction": "NW" })

  describe "matching simple addresses" do
    test "explicit addresses match correctly" do
      assert :ok = @addr1
      |> Jason.decode!
      |> Properties.address1
    end

    test "deficient properties match correctly" do
      assert :ok = @addr3
      |> Jason.decode!
      |> Properties.address1
    end

    test "empty object matches correctly" do
      assert :ok = Properties.address1(%{})
    end

    test "extra properties matches correctly" do
      assert :ok = @addr4
      |> Jason.decode!
      |> Properties.address1
    end

    test "mismatched inner property doesn't match" do
      assert {:mismatch, {ExonerateTest.Macro.Tutorial.ObjectTest.Properties, :address1, @addr2}} =
        @addr2
        |> Jason.decode!
        |> Properties.address1
    end
  end

end
