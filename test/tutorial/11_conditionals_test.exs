defmodule ExonerateTest.Tutorial.ConditionalsTest do
  use ExUnit.Case, async: true

  @moduletag :generic
  @moduletag :tutorial

  defmodule PropertyDependencies do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#property-dependencies

    """
    require Exonerate

    Exonerate.function_from_string(
      :def,
      :dependency1,
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
    )

    Exonerate.function_from_string(:def, :dependency2, """
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
    """)
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
      assert :ok =
               @propdependency1
               |> Jason.decode!()
               |> PropertyDependencies.dependency1()
    end

    test "failing to meet dependency mismatches" do
      propdependency2 = Jason.decode!(@propdependency2)
      assert {:error, list} = PropertyDependencies.dependency1(propdependency2)

      assert list[:schema_pointer] == "/dependencies/credit_card/0"
      assert list[:error_value] == propdependency2
      assert list[:json_pointer] == "/"
    end

    test "no dependency doesn't need to be met" do
      assert :ok =
               @propdependency3
               |> Jason.decode!()
               |> PropertyDependencies.dependency1()
    end

    test "dependency is one-way" do
      assert :ok =
               @propdependency4
               |> Jason.decode!()
               |> PropertyDependencies.dependency1()
    end
  end

  describe "matching two-way dependency" do
    test "one-way dependency mismatches" do
      propdependency2 = Jason.decode!(@propdependency2)
      assert {:error, list} = PropertyDependencies.dependency2(propdependency2)

      assert list[:schema_pointer] == "/dependencies/credit_card/0"
      assert list[:error_value] == propdependency2
      assert list[:json_pointer] == "/"
    end

    test "dependency is now two-way" do
      propdependency4 = Jason.decode!(@propdependency4)
      assert {:error, list} = PropertyDependencies.dependency2(propdependency4)

      assert list[:schema_pointer] == "/dependencies/billing_address/0"
      assert list[:error_value] == propdependency4
      assert list[:json_pointer] == "/"
    end
  end

  defmodule SchemaDependencies do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#schema-dependencies

    """
    require Exonerate

    Exonerate.function_from_string(
      :def,
      :schemadependency,
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
    )
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
      assert :ok =
               @schemadependency1
               |> Jason.decode!()
               |> SchemaDependencies.schemadependency()
    end

    test "partial compliance does not work" do
      schemadependency2 = Jason.decode!(@schemadependency2)
      assert {:error, list} = SchemaDependencies.schemadependency(schemadependency2)

      assert list[:schema_pointer] == "/dependencies/credit_card/required/0"
      assert list[:error_value] == %{"credit_card" => 5_555_555_555_555_555, "name" => "John Doe"}
      assert list[:json_pointer] == "/"
    end

    test "omitting a trigger works" do
      assert :ok =
               @schemadependency3
               |> Jason.decode!()
               |> SchemaDependencies.schemadependency()
    end
  end
end
