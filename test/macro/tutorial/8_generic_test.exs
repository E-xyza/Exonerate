defmodule ExonerateTest.Macro.Tutorial.GenericTest do
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
    import Exonerate.Macro

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

end
