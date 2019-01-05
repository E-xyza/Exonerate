defmodule ExonerateTest.Macro.Tutorials.BasicsTest do
  use ExUnit.Case, async: true

  @moduletag :one

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/basics.html

  Literally conforms to all the tests presented in this document.
  """

  defmodule HelloWorld do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#hello-world
    """
    import Exonerate.Macro

    defschema helloworld1: "{}"
    defschema helloworld2: "true"
    defschema "false matches nothing": "false"
  end

  describe "the hello world basic test" do
    test "empty object matches everything" do
      assert :ok = HelloWorld.helloworld1(42)
      assert :ok = HelloWorld.helloworld1("i'm a string")
      assert :ok = HelloWorld.helloworld1(%{ "an" => [ "arbitrarily", "nested" ], "data" => "structure" })
    end

    test "true matches everything" do
      assert :ok = HelloWorld.helloworld2(42)
      assert :ok = HelloWorld.helloworld2("i'm a string")
      assert :ok = HelloWorld.helloworld2(%{ "an" => [ "arbitrarily", "nested" ], "data" => "structure" })
    end

    test "false matches nothing" do
      assert {:mismatch, {ExonerateTest.Macro.Tutorials.BasicsTest.HelloWorld, "false matches nothing"}, "Resistance is futile...  This will always fail!!!"} =
        HelloWorld."false matches nothing"("Resistance is futile...  This will always fail!!!")
    end
  end

  defmodule TypeKeyword do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#the-type-keyword
    """
    import Exonerate.Macro

    defschema type: ~s({"type": "string"})
  end

  describe "the type keyword test" do
    test "string type matches string" do
      assert :ok = TypeKeyword.type("I'm a string")
    end

    test "string type does not match nonstring" do
      assert {:mismatch, {ExonerateTest.Macro.Tutorials.BasicsTest.TypeKeyword, "type"}, 42} = TypeKeyword.type(42)
    end
  end
end
