defmodule ExonerateTest.Tutorial.ArrayTest do
  use ExUnit.Case, async: true

  @moduletag :array

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/array.html
  Literally conforms to all the tests presented in this document.
  """

  defmodule Array do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#array

    """
    import Exonerate

    defschema array: ~s({ "type": "array" })

  end

  describe "basic array type matching" do
    test "an array" do
      assert :ok = ~s([1, 2, 3, 4, 5])
      |> Jason.decode!
      |> Array.array
    end

    test "different types of values are ok" do
      assert :ok = ~s([3, "different", { "types" : "of values" }])
      |> Jason.decode!
      |> Array.array
    end

    test "object doesn't match array" do
      assert  {:mismatch, {"#", %{"Not" => "an array"}}} ==
        Array.array(%{"Not" => "an array"})
    end
  end

  defmodule ListValidation do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#list-validation

    """
    import Exonerate

    defschema items: """
    {
      "type": "array",
      "items": {
        "type": "number"
      }
    }
    """

    defschema contains: """
    {
      "type": "array",
      "contains": {
        "type": "number"
      }
    }
    """

  end

  describe "basic array items matching" do
    test "an array of numbers" do
      assert :ok = ~s([1, 2, 3, 4, 5])
      |> Jason.decode!
      |> ListValidation.items
    end

    test "one non-number ruins the party" do
      assert  {:mismatch, {"#/items", "3"}} ==
        ListValidation.items([1, 2, "3", 4, 5])
    end

    test "an empty array passes" do
      assert :ok = ~s([])
      |> Jason.decode!
      |> ListValidation.items
    end
  end

  describe "basic array contains matching" do
    test "a single number is enough to make it pass" do
      assert :ok = ~s(["life", "universe", "everything", 42])
      |> Jason.decode!
      |> ListValidation.contains
    end

    test "it fails with no numbers" do
      assert  {:mismatch,
        {"#", ["life", "universe", "everything", "forty-two"]}} ==
          ListValidation.contains(["life", "universe", "everything", "forty-two"])
    end

    test "all numbers is ok" do
      assert :ok = ~s([1, 2, 3, 4, 5])
      |> Jason.decode!
      |> ListValidation.items
    end
  end

  defmodule TupleValidation do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#tuple-validation

    """
    import Exonerate

    defschema tuple: """
    {
      "type": "array",
      "items": [
        {
          "type": "number"
        },
        {
          "type": "string"
        },
        {
          "type": "string",
          "enum": ["Street", "Avenue", "Boulevard"]
        },
        {
          "type": "string",
          "enum": ["NW", "NE", "SW", "SE"]
        }
      ]
    }
    """

    defschema tuple_noadditional: """
    {
      "type": "array",
      "items": [
        {
          "type": "number"
        },
        {
          "type": "string"
        },
        {
          "type": "string",
          "enum": ["Street", "Avenue", "Boulevard"]
        },
        {
          "type": "string",
          "enum": ["NW", "NE", "SW", "SE"]
        }
      ],
      "additionalItems": false
    }
    """


    defschema tuple_additional_with_property:
    """
    {
      "type": "array",
      "items": [
        {
          "type": "number"
        },
        {
          "type": "string"
        },
        {
          "type": "string",
          "enum": ["Street", "Avenue", "Boulevard"]
        },
        {
          "type": "string",
          "enum": ["NW", "NE", "SW", "SE"]
        }
      ],
      "additionalItems": { "type": "string" }
    }
    """
  end

  describe "tuple validation" do
    test "a single number is enough to make it pass" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW"])
      |> Jason.decode!
      |> TupleValidation.tuple
    end

    test "drive is not an acceptable street type" do
      assert  {:mismatch, {"#/items/2", "Drive"}}
        == TupleValidation.tuple([24, "Sussex", "Drive"])
    end

    test "address is missing a street number" do
      assert  {:mismatch, {"#/items/0", "Palais de l'Élysée"}} ==
        TupleValidation.tuple(["Palais de l'Élysée"])
    end

    test "it's ok to not have all the items" do
      assert :ok = ~s([10, "Downing", "Street"])
      |> Jason.decode!
      |> TupleValidation.tuple
    end

    test "it's ok to have extra items" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW", "Washington"])
      |> Jason.decode!
      |> TupleValidation.tuple
    end
  end

  describe "tuple validation can happen with additionalItems" do
    test "the basic still passes" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW"])
      |> Jason.decode!
      |> TupleValidation.tuple_noadditional
    end

    test "it is ok to not provide all the items" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue"])
      |> Jason.decode!
      |> TupleValidation.tuple_noadditional
    end

    test "it is not ok to provide extra items" do
      assert  {:mismatch,{"#/additional_items", "Washington"}} ==
        TupleValidation.tuple_noadditional(
          [1600, "Pennsylvania", "Avenue", "NW", "Washington"])
    end
  end

  describe "tuple validation can happen with additionalItems and properties" do
    test "extra strings are ok" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW", "Washington"])
      |> Jason.decode!
      |> TupleValidation.tuple_additional_with_property
    end

    test "but not extra numbers" do
      assert  {:mismatch, {"#/additional_items", 20500}} ==
        TupleValidation.tuple_additional_with_property(
          [1600, "Pennsylvania", "Avenue", "NW", 20500])
    end
  end

  defmodule Length do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#length

    """
    import Exonerate

    defschema length: """
    {
      "type": "array",
      "minItems": 2,
      "maxItems": 3
    }
    """
  end

  describe "array length works" do
    test "by length" do
      assert {:mismatch, {"#", []}} == Length.length([])
      assert :ok == Length.length([1, 2])
      assert :ok == Length.length([1, 2, 3])
      assert {:mismatch, {"#", [1, 2, 3, 4]}} == Length.length([1, 2, 3, 4])
    end
  end

  defmodule Uniqueness do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#uniqueness

    """
    import Exonerate

    defschema unique: """
    {
      "type": "array",
      "uniqueItems": true
    }
    """
  end

  describe "array uniqueness works" do
    test "for arrays" do
      assert :ok = Uniqueness.unique([1, 2, 3, 4, 5])

      assert {:mismatch, {"#", [1, 2, 3, 3, 4]}} ==
        Uniqueness.unique([1, 2, 3, 3, 4])
    end

    test "empty array always passes" do
      assert :ok = Uniqueness.unique([])
    end
  end

end
