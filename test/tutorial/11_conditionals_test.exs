defmodule ExonerateTest.Tutorial.ConditionalsTest do
  use ExUnit.Case, async: true

  @moduletag :generic
  @moduletag :tutorial

  defmodule PropertyDependencies do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#property-dependencies

    """
    import Exonerate

    defschema dependency1:
    """
    {
      "type": "object",

      "properties": {
        "name": { "type": "string" },
        "credit_card": { "type": "number" },
        "billing_address": { "type": "string" }
      },

      "required": ["name"],

      "dependencies": {
        "credit_card": ["billing_address"]
      }
    }
    """

    defschema dependency2:
    """
    {
      "type": "object",

      "properties": {
        "name": { "type": "string" },
        "credit_card": { "type": "number" },
        "billing_address": { "type": "string" }
      },

      "required": ["name"],

      "dependencies": {
        "credit_card": ["billing_address"],
        "billing_address": ["credit_card"]
      }
    }
    """
  end

  @propdependency1 """
  {
    "name": "John Doe",
    "credit_card": 5555555555555555,
    "billing_address": "555 Debtor's Lane"
  }
  """
  @propdependency2 """
  {
    "name": "John Doe",
    "credit_card": 5555555555555555
  }
  """
  @propdependency3 ~s({"name": "John Doe"})
  @propdependency4 """
  {
    "name": "John Doe",
    "billing_address": "555 Debtor's Lane"
  }
  """

  describe "matching one-way dependency" do
    test "meeting dependency matches" do
      assert :ok = @propdependency1
      |> Jason.decode!
      |> PropertyDependencies.dependency1
    end
    test "failing to meet dependency mismatches" do
      propdependency2 = Jason.decode!(@propdependency2)
      assert {:error, list} =
        PropertyDependencies.dependency1(propdependency2)

      assert list[:schema_path] == "dependency1#!/dependencies/credit_card/0"
      assert list[:error_value] == propdependency2
      assert list[:json_path] == "/"
    end
    test "no dependency doesn't need to be met" do
      assert :ok = @propdependency3
      |> Jason.decode!
      |> PropertyDependencies.dependency1
    end
    test "dependency is one-way" do
      assert :ok = @propdependency4
      |> Jason.decode!
      |> PropertyDependencies.dependency1
    end
  end

  describe "matching two-way dependency" do
    test "one-way dependency mismatches" do
      propdependency2 = Jason.decode!(@propdependency2)
      assert {:error, list} =
        PropertyDependencies.dependency2(propdependency2)

      assert list[:schema_path] == "dependency2#!/dependencies/credit_card/0"
      assert list[:error_value] == propdependency2
      assert list[:json_path] == "/"
    end

    test "dependency is now two-way" do
      propdependency4 = Jason.decode!(@propdependency4)
      assert {:error, list} =
        PropertyDependencies.dependency2(propdependency4)

      assert list[:schema_path] == "dependency2#!/dependencies/billing_address/0"
      assert list[:error_value] == propdependency4
      assert list[:json_path] == "/"
    end
  end

  defmodule SchemaDependencies do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#schema-dependencies

    """
    import Exonerate

    defschema schemadependency:
    """
    {
      "type": "object",

      "properties": {
        "name": { "type": "string" },
        "credit_card": { "type": "number" }
      },

      "required": ["name"],

      "dependencies": {
        "credit_card": {
          "properties": {
            "billing_address": { "type": "string" }
          },
          "required": ["billing_address"]
        }
      }
    }
    """

  end

  @schemadependency1 """
  {
    "name": "John Doe",
    "credit_card": 5555555555555555,
    "billing_address": "555 Debtor's Lane"
  }
  """
  @schemadependency2 """
  {
    "name": "John Doe",
    "credit_card": 5555555555555555
  }
  """
  @schemadependency3 """
  {
    "name": "John Doe",
    "billing_address": "555 Debtor's Lane"
  }
  """

  describe "matching schema dependency" do
    test "full compliance works" do
      assert :ok = @schemadependency1
      |> Jason.decode!
      |> SchemaDependencies.schemadependency
    end
    test "partial compliance does not work" do
      schemadependency2 = Jason.decode!(@schemadependency2)
      assert {:error, list} =
        SchemaDependencies.schemadependency(schemadependency2)

      assert list[:schema_path] == "schemadependency#!/dependencies/credit_card/required/0"
      assert list[:error_value] == %{"credit_card" => 5555555555555555, "name" => "John Doe"}
      assert list[:json_path] == "/"
    end
    test "omitting a trigger works" do
      assert :ok = @schemadependency3
      |> Jason.decode!
      |> SchemaDependencies.schemadependency
    end
  end


#  @moduledoc """
#  basic tests from:
#
#  https://json-schema.org/understanding-json-schema/reference/generic.html
#  Literally conforms to all the tests presented in this document.
#  """
#
#  defmodule Metadata do
#    @moduledoc """
#    tests from:
#
#    https://json-schema.org/understanding-json-schema/reference/generic.html#metadata
#    """
#    import Exonerate
#
#    defschema metadata: """
#    {
#      "title" : "Match anything",
#      "description" : "This is a schema that matches anything.",
#      "default" : "Default value",
#      "examples" : [
#        "Anything",
#        4035
#      ]
#    }
#    """
#  end
#
#  describe "metadata are stored" do
#    @tag :metadata
#    test "the title is included" do
#      assert "Match anything" == Metadata.metadata(:title)
#    end
#
#    @tag :metadata
#    test "the description is included" do
#      assert "This is a schema that matches anything." == Metadata.metadata(:description)
#    end
#
#    @tag :metadata
#    test "the default value is included" do
#      assert "Default value" == Metadata.metadata(:default)
#    end
#
#    @tag :metadata
#    test "the example values are included" do
#      assert ["Anything", 4035] == Metadata.metadata(:examples)
#    end
#  end
#
#  defmodule EnumeratedValues do
#    @moduledoc """
#    tests from:
#
#    https://json-schema.org/understanding-json-schema/reference/generic.html#enumerated-values
#    """
#    import Exonerate
#
#    defschema enum1: """
#    {
#      "type": "string",
#      "enum": ["red", "amber", "green"]
#    }
#    """
#
#    defschema enum2: """
#    {
#      "enum": ["red", "amber", "green", null, 42]
#    }
#    """
#
#    defschema enum3: """
#    {
#      "type": "string",
#      "enum": ["red", "amber", "green", null]
#    }
#    """
#  end
#
#  @moduletag :one
#
#  describe "basic enums work" do
#    test "specific values match" do
#      assert :ok == EnumeratedValues.enum1("red")
#    end
#
#    test "unenumerated values don't match" do
#      assert {:error, list} = EnumeratedValues.enum1("blue")
#
#      assert list[:schema_path] == "enum1#!/enum"
#      assert list[:error_value] == "blue"
#      assert list[:json_path] == "/"
#    end
#  end
#
#  describe "enums work across types" do
#    test "specific values match" do
#      assert :ok == EnumeratedValues.enum2("red")
#      assert :ok == EnumeratedValues.enum2(nil)
#      assert :ok == EnumeratedValues.enum2(42)
#    end
#
#    test "unenumerated values don't match" do
#      assert  {:error, list} = EnumeratedValues.enum2(0)
#
#      assert list[:schema_path] == "enum2#!/enum"
#      assert list[:error_value] == 0
#      assert list[:json_path] == "/"
#    end
#  end
#
#  describe "enums must be valid with the enclosing schema" do
#    test "specific values match" do
#      assert :ok == EnumeratedValues.enum3("red")
#    end
#
#    test "unenumerated values don't match" do
#      assert {:error, list} = EnumeratedValues.enum3(nil)
#
#      assert list[:schema_path] == "enum3#!/type"
#      assert list[:error_value] == nil
#      assert list[:json_path] == "/"
#    end
#  end
#
#  defmodule ConstantValues do
#    @moduledoc """
#    tests from:
#
#    https://json-schema.org/understanding-json-schema/reference/generic.html#constant-values
#    """
#    import Exonerate
#
#    defschema const: """
#    {
#      "properties": {
#        "country": {
#          "const": "United States of America"
#        }
#      }
#    }
#    """
#  end
#
#  describe "consts restrict to a single value" do
#    test "specific values match" do
#      assert :ok == ConstantValues.const(%{"country" => "United States of America"})
#    end
#
#    test "unenumerated values don't match" do
#      assert {:error, list} = ConstantValues.const(%{"country" => "Canada"})
#
#      assert list[:schema_path] == "const#!/properties/country/const"
#      assert list[:error_value] == "Canada"
#      assert list[:json_path] == "/country"
#    end
#  end
end
