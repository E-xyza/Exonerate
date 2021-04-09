defmodule ExonerateTest.Tutorial.TypeSpecificTest do
  use ExUnit.Case, async: true

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/type.html

  Literally conforms to all the tests presented in this document.
  """

  defmodule Type do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/type.html#type-specific-keywords
    """
    import Exonerate

    defschema one_type: ~s({ "type": "number" })
    defschema two_types: ~s({ "type": [ "number", "string" ] })
  end

  describe "the type specific tests simple example" do
    test "number matches multiple types of number" do
      assert :ok = Type.one_type(42)
      assert :ok = Type.one_type(42.0)
    end

    test "number mismatches a string" do
      assert {:error, list} = Type.one_type("42")
      assert list[:schema_path] == "one_type#type"
      assert list[:error_value] == "42"
      assert list[:json_path] == "#"
    end
  end

  describe "the type specific tests list example" do
    test "compound matches scalars" do
      assert :ok = Type.two_types(42)
      assert :ok = Type.two_types("Life, the universe, and everything")
    end

    @struct_list ["Life", "the universe", "and everything"]
    test "number mismatches a structured type" do
      assert {:error, list} = Type.two_types(@struct_list)
      assert list[:schema_path] == "two_types#type"
      assert list[:error_value] == @struct_list
      assert list[:json_path] == "#"
    end
  end

end
