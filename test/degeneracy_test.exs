defmodule ExonerateTest.DegeneracyTest do
  use ExUnit.Case, async: true

  # tests to make sure that degeneracy works as expected.

  require Exonerate

  describe "exclusive extrema, modern" do
    Exonerate.function_from_string(:def, :max, """
    {
      "exclusiveMaximum": 15,
      "maximum": 10
    }
    """)

    test "maximum dominates" do
      assert :ok = max(7)
      assert {:error, list} = max(10.1)
      assert "#/maximum" = list[:absolute_keyword_location]

      assert {:error, list} = max(15)
      assert "#/maximum" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :min, """
    {
      "exclusiveMinimum": 10,
      "minimum": 15
    }
    """)

    test "minimum dominates" do
      assert :ok = min(20)
      assert {:error, list} = min(14.9)
      assert "#/minimum" = list[:absolute_keyword_location]

      assert {:error, list} = min(10)
      assert "#/minimum" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :emax, """
    {
      "exclusiveMaximum": 10,
      "maximum": 15
    }
    """)

    test "exclusive maximum dominates" do
      assert :ok = emax(7)
      assert {:error, list} = emax(10)
      assert "#/exclusiveMaximum" = list[:absolute_keyword_location]

      assert {:error, list} = emax(15)
      assert "#/exclusiveMaximum" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :emin, """
    {
      "exclusiveMinimum": 15,
      "minimum": 10
    }
    """)

    test "exclusive minimum dominates" do
      assert :ok = min(20)
      assert {:error, list} = emin(15)
      assert "#/exclusiveMinimum" = list[:absolute_keyword_location]

      assert {:error, list} = emin(10)
      assert "#/exclusiveMinimum" = list[:absolute_keyword_location]
    end
  end

  describe "boolean exclusives" do
    Exonerate.function_from_string(:def, :emax_bool, """
    {
      "exclusiveMaximum": true,
      "multipleOf": 2
    }
    """)

    test "exclusive maximum" do
      assert :ok = emax_bool(2)
    end

    Exonerate.function_from_string(:def, :emin_bool, """
    {
      "exclusiveMinimum": true,
      "multipleOf": 2
    }
    """)

    test "exclusive minimum" do
      assert :ok = emin_bool(2)
    end
  end

  describe "minimum content" do
    Exonerate.function_from_string(:def, :minlength, """
    {
      "minLength": 0
    }
    """)

    test "minlength" do
      assert :ok = minlength("")
      assert :ok = minlength("foo")
    end

    Exonerate.function_from_string(:def, :minitems, """
    {
      "minItems": 0
    }
    """)

    test "minItems" do
      assert :ok = minitems([])
      assert :ok = minitems(["foo"])
    end

    Exonerate.function_from_string(:def, :minproperties, """
    {
      "minProperties": 0
    }
    """)

    test "minProperties" do
      assert :ok = minproperties(%{})
      assert :ok = minproperties(%{"foo" => "bar"})
    end

    Exonerate.function_from_string(:def, :null_regex, """
    {
      "pattern": ""
    }
    """)

    test "null regex" do
      assert :ok = null_regex("")
      assert :ok = null_regex("foo")
    end

    Exonerate.function_from_string(:def, :all_regex, """
    {
      "pattern": ".*"
    }
    """)

    test "all regex" do
      assert :ok = all_regex("")
      assert :ok = all_regex("foo")
    end

    Exonerate.function_from_string(:def, :empty_allof, """
    {
      "allOf": []
    }
    """)

    test "empty allof" do
      assert :ok = empty_allof("foo")
    end
  end

  describe "const and enum in the same context" do
    Exonerate.function_from_string(:def, :redundant, """
    {
      "enum": ["foo", "bar"],
      "const": "foo"
    }
    """)

    test "redundant" do
      assert :ok = redundant("foo")
      assert {:error, list} = redundant("bar")
      assert "#/const" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :disjoint, """
    {
      "enum": ["foo"],
      "const": "bar"
    }
    """)

    test "disjoint" do
      assert {:error, list} = disjoint("bar")
      assert "#/enum" = list[:absolute_keyword_location]
      assert {:error, list} = disjoint("foo")
      assert "#/const" = list[:absolute_keyword_location]
    end
  end
end
