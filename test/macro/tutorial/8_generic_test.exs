defmodule ExonerateTest.Tutorial.GenericTest do
  use ExUnit.Case, async: true

  @moduletag :generic

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/generic.html
  Literally conforms to all the tests presented in this document.
  """

  defmodule Metadata do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/generic.html#metadata
    """
    import Exonerate

    defschema metadata: """
    {
      "title" : "Match anything",
      "description" : "This is a schema that matches anything.",
      "default" : "Default value",
      "examples" : [
        "Anything",
        4035
      ]
    }
    """
  end

  describe "metadata are stored" do
    test "the title is included" do
      assert "Match anything" == Metadata.metadata(:title)
    end

    test "the description is included" do
      assert "This is a schema that matches anything." == Metadata.metadata(:description)
    end

    test "the default value is included" do
      assert "Default value" == Metadata.metadata(:default)
    end

    test "the example values are included" do
      assert ["Anything", 4035] == Metadata.metadata(:examples)
    end
  end

  defmodule EnumeratedValues do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/generic.html#enumerated-values
    """
    import Exonerate

    defschema enum1: """
    {
      "type": "string",
      "enum": ["red", "amber", "green"]
    }
    """

    defschema enum2: """
    {
      "enum": ["red", "amber", "green", null, 42]
    }
    """

    defschema enum3: """
    {
      "type": "string",
      "enum": ["red", "amber", "green", null]
    }
    """
  end

  @moduletag :one

  describe "basic enums work" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum1("red")
    end

    test "unenumerated values don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.GenericTest.EnumeratedValues,
      :enum1, ["blue"]}}
      = EnumeratedValues.enum1("blue")
    end
  end

  describe "enums work across types" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum2("red")
      assert :ok == EnumeratedValues.enum2(nil)
      assert :ok == EnumeratedValues.enum2(42)
    end

    test "unenumerated values don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.GenericTest.EnumeratedValues,
      :enum2, [0]}}
      = EnumeratedValues.enum2(0)
    end
  end

  describe "enums must be valid with the enclosing schema" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum3("red")
    end

    test "unenumerated values don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.GenericTest.EnumeratedValues,
      :enum3___enclosing, [nil]}}
      = EnumeratedValues.enum3(nil)
    end
  end

  defmodule ConstantValues do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/generic.html#constant-values
    """
    import Exonerate

    defschema const: """
    {
      "properties": {
        "country": {
          "const": "United States of America"
        }
      }
    }
    """
  end

  describe "consts restrict to a single value" do
    test "specific values match" do
      assert :ok == ConstantValues.const(%{"country" => "United States of America"})
    end

    test "unenumerated values don't match" do
      assert  {:mismatch,
      {ExonerateTest.Tutorial.GenericTest.ConstantValues,
      :const___properties__country, ["Canada"]}}
      = ConstantValues.const(%{"country" => "Canada"})
    end
  end
end
