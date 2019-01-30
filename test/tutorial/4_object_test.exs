defmodule ExonerateTest.Tutorial.ObjectTest do
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
    import Exonerate

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
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Object, :object, ["Not an object"]}} =
        Object.object("Not an object")

      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Object, :object, [@badarray]}} =
        Object.object(@badarray)
    end
  end

  defmodule Properties do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#properties

    """
    import Exonerate

    defschema address1:
    """
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

    defschema address2:
    """
    {
      "type": "object",
      "properties": {
        "number":      { "type": "number" },
        "street_name": { "type": "string" },
        "street_type": { "type": "string",
                         "enum": ["Street", "Avenue", "Boulevard"]
                       }
      },
      "additionalProperties": false
    }
    """

    defschema address3:
    """
    {
      "type": "object",
      "properties": {
        "number":      { "type": "number" },
        "street_name": { "type": "string" },
        "street_type": { "type": "string",
                         "enum": ["Street", "Avenue", "Boulevard"]
                       }
      },
      "additionalProperties": { "type": "string" }
    }
    """
  end

  @addr1 ~s({ "number": 1600, "street_name": "Pennsylvania", "street_type": "Avenue" })
  @addr2 ~s({ "number": "1600", "street_name": "Pennsylvania", "street_type": "Avenue" })
  @addr3 ~s({ "number": 1600, "street_name": "Pennsylvania" })
  @addr4 ~s({ "number": 1600, "street_name": "Pennsylvania", "street_type": "Avenue", "direction": "NW" })
  @addr5 ~s({ "number": 1600, "street_name": "Pennsylvania", "street_type": "Avenue","office_number": 201  })

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
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Properties, :address1__properties__number, ["1600"]}} =
        @addr2
        |> Jason.decode!
        |> Properties.address1
    end
  end

  describe "matching addresses with additionalProperties forbidden" do
    test "explicit addresses match correctly" do
      assert :ok = @addr1
      |> Jason.decode!
      |> Properties.address2
    end

    test "extra properties matches correctly" do
      addr4 = Jason.decode(@addr4)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Properties, :address2, [addr4]}} =
        Properties.address2(addr4)
    end
  end

  describe "matching addresses with additionalProperties as an object" do
    test "explicit addresses match correctly" do
      assert :ok = @addr1
      |> Jason.decode!
      |> Properties.address3
    end

    test "matching additionalProperties matches correctly" do
      assert :ok = @addr4
      |> Jason.decode!
      |> Properties.address3
    end

    test "extra nonstring property doesn't matche" do
      addr5 = Jason.decode(@addr5)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Properties, :address2, [addr5]}} =
        Properties.address2(addr5)
    end
  end

  defmodule RequiredProperties do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#required-properties

    """
    import Exonerate

    defschema contactinfo:
    """
    {
      "type": "object",
      "properties": {
        "name":      { "type": "string" },
        "email":     { "type": "string" },
        "address":   { "type": "string" },
        "telephone": { "type": "string" }
      },
      "required": ["name", "email"]
    }
    """
  end

  @contact1 """
  {
    "name": "William Shakespeare",
    "email": "bill@stratford-upon-avon.co.uk"
  }
  """
  @contact2 """
  {
    "name": "William Shakespeare",
    "email": "bill@stratford-upon-avon.co.uk",
    "address": "Henley Street, Stratford-upon-Avon, Warwickshire, England",
    "authorship": "in question"
  }
  """
  @contact3 """
  {
    "name": "William Shakespeare",
    "address": "Henley Street, Stratford-upon-Avon, Warwickshire, England"
  }
  """

  describe "matching required properties" do
    test "basic contact matches correctly" do
      assert :ok = @contact1
      |> Jason.decode!
      |> RequiredProperties.contactinfo
    end

    test "extra info doesn't invalidate match" do
      assert :ok = @contact2
      |> Jason.decode!
      |> RequiredProperties.contactinfo
    end

    test "deficient info is a problem" do
      contact3 = Jason.decode!(@contact3)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.RequiredProperties, :contactinfo, [contact3]}} =
        RequiredProperties.contactinfo(contact3)
    end
  end

  defmodule PropertyNames do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#property-names

    """
    import Exonerate

    defschema token:
    """
    {
      "type": "object",
      "propertyNames": {
       "pattern": "^[A-Za-z_][A-Za-z0-9_]*$"
      }
    }
    """
  end

  @token1 ~s({ "_a_proper_token_001": "value" })
  @token2 ~s({ "001 invalid": "value" })

  describe "matching property names" do
    test "basic contact matches correctly" do
      assert :ok = @token1
      |> Jason.decode!
      |> PropertyNames.token
    end

    test "not matching the property name doesn't match" do
      token2 = Jason.decode!(@token2)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PropertyNames, :token__property_names, ["001 invalid"]}} =
        PropertyNames.token(token2)
    end
  end

  defmodule Size do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#size

    """
    import Exonerate

    defschema object:
    """
    {
      "type": "object",
      "minProperties": 2,
      "maxProperties": 3
    }
    """
  end

  @objsize1 ~s({})
  @objsize2 ~s({ "a": 0 })
  @objsize3 ~s({ "a": 0, "b": 1 })
  @objsize4 ~s({ "a": 0, "b": 1, "c": 2 })
  @objsize5 ~s({ "a": 0, "b": 1, "c": 2, "d": 3 })

  describe "matching property size" do
    test "empty object mismatches" do
      objsize1 = Jason.decode!(@objsize1)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Size, :object, [objsize1]}} =
        Size.object(objsize1)
    end

    test "too small object mismatches" do
      objsize2 = Jason.decode!(@objsize2)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Size, :object, [objsize2]}} =
        Size.object(objsize2)
    end

    test "small goldilocks matches correctly" do
      assert :ok = @objsize3
      |> Jason.decode!
      |> Size.object
    end

    test "big goldilocks matches correctly" do
      assert :ok = @objsize4
      |> Jason.decode!
      |> Size.object
    end

    test "too large object mismatches" do
      objsize5 = Jason.decode!(@objsize5)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.Size, :object, [objsize5]}} =
        Size.object(objsize5)
    end
  end

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
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PropertyDependencies, :dependency1__dependencies__credit_card, [propdependency2]}} =
        PropertyDependencies.dependency1(propdependency2)
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
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PropertyDependencies, :dependency2__dependencies__credit_card, [propdependency2]}} =
        PropertyDependencies.dependency2(propdependency2)
    end
    test "dependency is now two-way" do
      propdependency4 = Jason.decode!(@propdependency4)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PropertyDependencies, :dependency2__dependencies__billing_address, [propdependency4]}} =
        PropertyDependencies.dependency2(propdependency4)
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
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.SchemaDependencies, :schemadependency__dependencies__credit_card, [schemadependency2]}} =
        SchemaDependencies.schemadependency(schemadependency2)
    end
    test "omitting a trigger works" do
      assert :ok = @schemadependency3
      |> Jason.decode!
      |> SchemaDependencies.schemadependency
    end
  end

  defmodule PatternProperties do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/object.html#pattern-properties

    """
    import Exonerate

    defschema patternprop1:
    """
    {
      "type": "object",
      "patternProperties": {
        "^S_": { "type": "string" },
        "^I_": { "type": "integer" }
      },
      "additionalProperties": false
    }
    """
  end

  @patternmatch1 ~s({ "S_25": "This is a string" })
  @patternmatch2 ~s({ "I_0": 42 })
  @patternmatch3 ~s({ "S_0": 42 })
  @patternmatch4 ~s({ "I_42": "This is a string" })
  @patternmatch5 ~s({ "keyword": "value" })

  describe "matching pattern properties without additionals" do
    test "string pattern works" do
      assert :ok = @patternmatch1
      |> Jason.decode!
      |> PatternProperties.patternprop1
    end
    test "integer pattern works" do
      assert :ok = @patternmatch2
      |> Jason.decode!
      |> PatternProperties.patternprop1
    end

    test "integers shouldn't match string pattern" do
      patternmatch3 = Jason.decode!(@patternmatch3)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PatternProperties, :patternprop1__pattern_properties_1, [42]}} =
        PatternProperties.patternprop1(patternmatch3)
    end
    test "strings shouldn't match integer pattern" do
      patternmatch4 = Jason.decode!(@patternmatch4)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PatternProperties, :patternprop1__pattern_properties_0, ["This is a string"]}} =
        PatternProperties.patternprop1(patternmatch4)
    end

    test "additional properties shouldn't match" do
      patternmatch5 = Jason.decode!(@patternmatch5)
      assert {:mismatch, {ExonerateTest.Tutorial.ObjectTest.PatternProperties, :patternprop1__additional_properties, ["value"]}} =
        PatternProperties.patternprop1(patternmatch5)
    end
  end
end
