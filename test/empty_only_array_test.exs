defmodule ExonerateTest.EmptyOnlyArrayTest do
  use ExUnit.Case, async: true

  # tests to make sure that some empty-only array conditions work

  require Exonerate

  describe "maxitems, 0" do
    Exonerate.function_from_string(:def, :trivial_maxitems, """
    {
      "maxItems": 0
    }
    """)

    test "fails unless empty" do
      assert :ok = trivial_maxitems([])
      assert {:error, list} = trivial_maxitems(["foo"])
      assert "#/maxItems" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :with_mincontains, """
    {
      "maxItems": 0,
      "contains": true,
      "minContains": 1
    }
    """)

    test "conflicts with mincontains" do
      assert {:error, list} = with_mincontains([])
      assert "#/minContains" = list[:absolute_keyword_location]
      assert {:error, list} = with_mincontains(["foo"])
      assert "#/maxItems" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :without_mincontains, """
    {
      "maxItems": 0,
      "contains": true
    }
    """)

    test "conflicts without mincontains" do
      assert {:error, list} = without_mincontains([])
      assert "#/contains" = list[:absolute_keyword_location]
      assert {:error, list} = without_mincontains(["foo"])
      assert "#/maxItems" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :with_mincontains_0, """
    {
      "maxItems": 0,
      "contains": true,
      "minContains": 0,
      "maxContains": 10
    }
    """)

    test "fails unless empty when minContains 0" do
      assert :ok = with_mincontains_0([])
      assert {:error, list} = with_mincontains_0(["foo"])
      assert "#/maxItems" = list[:absolute_keyword_location]
    end

    Exonerate.function_from_string(:def, :with_minitems, """
    {
      "maxItems": 0,
      "minItems": 1
    }
    """)

    test "fails with minItems > 0" do
      assert {:error, list} = with_minitems([])
      assert "#/minItems" = list[:absolute_keyword_location]
      assert {:error, list} = with_minitems(["foo"])
      assert "#/maxItems" = list[:absolute_keyword_location]
    end
  end
end
