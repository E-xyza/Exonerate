defmodule ExonerateTest.Tutorial.ArrayTest do
  use ExUnit.Case, async: true

  @moduletag :array
  @moduletag :tutorial

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
    require Exonerate

    Exonerate.function_from_string(:def, :array, ~s({ "type": "array" }))
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
      assert {:error, list} = Array.array(%{"Not" => "an array"})

      assert list[:schema_path] == "array#!/type"
      assert list[:error_value] == %{"Not" => "an array"}
      assert list[:json_path] == "/"
    end
  end

  defmodule ListValidation do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#list-validation

    """
    require Exonerate

    Exonerate.function_from_string(:def, :items, """
    {
      "type": "array",
      "items": {
        "type": "number"
      }
    }
    """)

    Exonerate.function_from_string(:def, :contains, """
    {
      "type": "array",
      "contains": {
        "type": "number"
      }
    }
    """)

  end

  describe "basic array items matching" do
    test "an array of numbers" do
      assert :ok = ~s([1, 2, 3, 4, 5])
      |> Jason.decode!
      |> ListValidation.items
    end

    test "one non-number ruins the party" do
      assert {:error, list} = ListValidation.items([1, 2, "3", 4, 5])

      assert list[:schema_path] == "items#!/items/type"
      assert list[:error_value] == "3"
      assert list[:json_path] == "/2"
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
      assert  {:error, list} =
          ListValidation.contains(["life", "universe", "everything", "forty-two"])

      assert list[:schema_path] == "contains#!/contains"
      assert list[:error_value] == ["life", "universe", "everything", "forty-two"]
      assert list[:json_path] == "/"
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
    require Exonerate

    Exonerate.function_from_string(:def, :tuple, """
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
    """)

    Exonerate.function_from_string(:def, :tuple_noadditional, """
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
    """)


    Exonerate.function_from_string(:def, :tuple_additional_with_property,
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
    """)
  end

  describe "tuple validation" do
    test "a single number is enough to make it pass" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW"])
      |> Jason.decode!
      |> TupleValidation.tuple
    end

    test "drive is not an acceptable street type" do
      assert  {:error, list} = TupleValidation.tuple([24, "Sussex", "Drive"])

      assert list[:schema_path] == "tuple#!/items/2/enum"
      assert list[:error_value] == "Drive"
      assert list[:json_path] == "/2"
    end

    test "address is missing a street number" do
      assert  {:error, list} =
        TupleValidation.tuple(["Palais de l'Élysée"])

      assert list[:schema_path] == "tuple#!/items/0/type"
      assert list[:error_value] == "Palais de l'Élysée"
      assert list[:json_path] == "/0"
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
      assert  {:error, list} =
        TupleValidation.tuple_noadditional(
          [1600, "Pennsylvania", "Avenue", "NW", "Washington"])

      assert list[:schema_path] == "tuple_noadditional#!/additionalItems"
      assert list[:error_value] == "Washington"
      assert list[:json_path] == "/4"
    end
  end

  describe "tuple validation can happen with additionalItems and properties" do
    test "extra strings are ok" do
      assert :ok = ~s([1600, "Pennsylvania", "Avenue", "NW", "Washington"])
      |> Jason.decode!
      |> TupleValidation.tuple_additional_with_property
    end

    test "but not extra numbers" do
      assert {:error, list} =
        TupleValidation.tuple_additional_with_property(
          [1600, "Pennsylvania", "Avenue", "NW", 20500])

      assert list[:schema_path] == "tuple_additional_with_property#!/additionalItems/type"
      assert list[:error_value] == 20500
      assert list[:json_path] == "/4"
    end
  end

  defmodule Length do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#length

    """
    require Exonerate

    Exonerate.function_from_string(:def, :length, """
    {
      "type": "array",
      "minItems": 2,
      "maxItems": 3
    }
    """)
  end

  describe "array length works" do
    test "by length" do
      assert {:error, list} = Length.length([])

      assert list[:schema_path] == "length#!/minItems"
      assert list[:error_value] == []
      assert list[:json_path] == "/"

      assert :ok == Length.length([1, 2])
      assert :ok == Length.length([1, 2, 3])

      assert {:error, list} = Length.length([1, 2, 3, 4])

      assert list[:schema_path] == "length#!/maxItems"
      assert list[:error_value] == [1, 2, 3, 4]
      assert list[:json_path] == "/"
    end
  end

  defmodule Uniqueness do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/array.html#uniqueness

    """
    require Exonerate

    Exonerate.function_from_string(:def, :unique, """
    {
      "type": "array",
      "uniqueItems": true
    }
    """)
  end

  describe "array uniqueness works" do
    test "for arrays" do
      assert :ok = Uniqueness.unique([1, 2, 3, 4, 5])

      assert {:error, list} = Uniqueness.unique([1, 2, 3, 3, 4])

      assert list[:schema_path] == "unique#!/uniqueItems"
      assert list[:error_value] == 3
      assert list[:json_path] == "/3"
    end

    test "empty array always passes" do
      assert :ok = Uniqueness.unique([])
    end
  end

end
