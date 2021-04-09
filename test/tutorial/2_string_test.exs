defmodule ExonerateTest.Tutorial.StringTest do
  use ExUnit.Case, async: true

  @moduletag :string

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/string.html

  Literally conforms to all the tests presented in this document.
  """

  defmodule String do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#string
    """
    import Exonerate

    defschema string: ~s({ "type": "string" })
  end

  describe "basic strings example" do
    test "various strings match correctly" do
      assert :ok = String.string("This is a string")
      assert :ok = String.string("Déjà vu")
      assert :ok = String.string("")
      assert :ok = String.string("42")
    end

    test "number mismatches a string" do
      assert {:error, list} = String.string(42)

      assert list[:schema_path] == "string#type"
      assert list[:error_value] == 42
      assert list[:json_path] == "#"
    end
  end

  defmodule Length do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#string
    """
    import Exonerate

    defschema string: """
                      {
                        "type": "string",
                        "minLength": 2,
                        "maxLength": 3
                      }
                      """
  end

  describe "strings length example" do
    test "string of correct sizes match" do
      assert :ok = Length.string("AB")
      assert :ok = Length.string("ABC")
    end

    test "string of incorrect sizes don't match" do
      assert {:error, list} = Length.string("A")

      assert list[:schema_path] == "string#minLength"
      assert list[:error_value] == "A"
      assert list[:json_path] == "#"

      assert {:error, list} = Length.string("ABCD")

      assert list[:schema_path] == "string#maxLength"
      assert list[:error_value] == "ABCD"
      assert list[:json_path] == "#"

    end
  end

  defmodule Pattern do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#regular-expressions
    """
    import Exonerate

    defschema string: """
                      {
                        "type": "string",
                        "pattern": "^(\\\\([0-9]{3}\\\\))?[0-9]{3}-[0-9]{4}$"
                      }
                      """
  end

  describe "strings pattern example" do
    test "telephone numbers match" do
      assert :ok = Pattern.string("555-1212")
      assert :ok = Pattern.string("(888)555-1212")
    end

    test "string of incorrect sizes don't match" do
      assert {:error, list} =
        Pattern.string("(888)555-1212 ext. 532")

      assert list[:schema_path] == "string#pattern"
      assert list[:error_value] == "(888)555-1212 ext. 532"
      assert list[:json_path] == "#"

      assert {:error, list} =
        Pattern.string("(800)FLOWERS")

      assert list[:schema_path] == "string#pattern"
      assert list[:error_value] == "(800)FLOWERS"
      assert list[:json_path] == "#"
    end
  end

end
