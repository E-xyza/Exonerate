defmodule ExonerateTest.Tutorial.GenericTest do
  use ExUnit.Case, async: true

  @moduletag :generic
  @moduletag :tutorial

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
    require Exonerate

    Exonerate.function_from_string(:def, :metadata, """
    {
      "title" : "Match anything",
      "description" : "This is a schema that matches anything.",
      "default" : "Default value",
      "examples" : [
        "Anything",
        4035
      ]
    }
    """)
  end

  describe "metadata are stored" do
    @tag :metadata
    test "the title is included" do
      assert "Match anything" == Metadata.metadata(:title)
    end

    @tag :metadata
    test "the description is included" do
      assert "This is a schema that matches anything." == Metadata.metadata(:description)
    end

    @tag :metadata
    test "the default value is included" do
      assert "Default value" == Metadata.metadata(:default)
    end

    @tag :metadata
    test "the example values are included" do
      assert ["Anything", 4035] == Metadata.metadata(:examples)
    end
  end

  defmodule EnumeratedValues do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/generic.html#enumerated-values
    """
    require Exonerate

    Exonerate.function_from_string(:def, :enum1, """
    {
      "type": "string",
      "enum": ["red", "amber", "green"]
    }
    """)

    Exonerate.function_from_string(:def, :enum2, """
    {
      "enum": ["red", "amber", "green", null, 42]
    }
    """)

    Exonerate.function_from_string(:def, :enum3, """
    {
      "type": "string",
      "enum": ["red", "amber", "green", null]
    }
    """)
  end

  @moduletag :one

  describe "basic enums work" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum1("red")
    end

    test "unenumerated values don't match" do
      assert {:error, list} = EnumeratedValues.enum1("blue")

      assert list[:schema_pointer] == "/enum"
      assert list[:error_value] == "blue"
      assert list[:json_pointer] == "/"
    end
  end

  describe "enums work across types" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum2("red")
      assert :ok == EnumeratedValues.enum2(nil)
      assert :ok == EnumeratedValues.enum2(42)
    end

    test "unenumerated values don't match" do
      assert  {:error, list} = EnumeratedValues.enum2(0)

      assert list[:schema_pointer] == "/enum"
      assert list[:error_value] == 0
      assert list[:json_pointer] == "/"
    end
  end

  describe "enums must be valid with the enclosing schema" do
    test "specific values match" do
      assert :ok == EnumeratedValues.enum3("red")
    end

    test "unenumerated values don't match" do
      assert {:error, list} = EnumeratedValues.enum3(nil)

      assert list[:schema_pointer] == "/enum"
      assert list[:error_value] == nil
      assert list[:json_pointer] == "/"
    end
  end

  defmodule ConstantValues do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/generic.html#constant-values
    """
    require Exonerate

    Exonerate.function_from_string(:def, :const, """
    {
      "properties": {
        "country": {
          "const": "United States of America"
        }
      }
    }
    """)
  end

  describe "consts restrict to a single value" do
    test "specific values match" do
      assert :ok == ConstantValues.const(%{"country" => "United States of America"})
    end

    test "unenumerated values don't match" do
      assert {:error, list} = ConstantValues.const(%{"country" => "Canada"})

      assert list[:schema_pointer] == "/properties/country/const"
      assert list[:error_value] == "Canada"
      assert list[:json_pointer] == "/country"
    end
  end
end
