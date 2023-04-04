defmodule ExonerateTest.Tutorial.BasicsTest do
  use ExUnit.Case, async: true

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/basics.html

  Literally conforms to all the tests presented in this document.
  """

  @moduletag :tutorial

  defmodule HelloWorld do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#hello-world
    """
    require Exonerate

    Exonerate.function_from_string(:def, :helloworld1, "{}")
    Exonerate.function_from_string(:def, :helloworld2, "true")
    Exonerate.function_from_string(:def, :helloworld3, "false")
  end

  describe "the hello world basic test" do
    test "empty object matches everything" do
      assert :ok = HelloWorld.helloworld1(42)
      assert :ok = HelloWorld.helloworld1("i'm a string")

      assert :ok =
               HelloWorld.helloworld1(%{"an" => ["arbitrarily", "nested"], "data" => "structure"})
    end

    test "true matches everything" do
      assert :ok = HelloWorld.helloworld2(42)
      assert :ok = HelloWorld.helloworld2("i'm a string")

      assert :ok =
               HelloWorld.helloworld2(%{"an" => ["arbitrarily", "nested"], "data" => "structure"})
    end

    test "false matches nothing" do
      assert {:error, list} =
               HelloWorld.helloworld3("Resistance is futile...  This will always fail!!!")

      assert list[:absolute_keyword_location] == "#/"
      assert list[:error_value] == "Resistance is futile...  This will always fail!!!"
      assert list[:instance_location] == "/"
    end
  end

  defmodule TypeKeyword do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#the-type-keyword
    """
    require Exonerate

    Exonerate.function_from_string(:def, :type, ~s({"type": "string"}))
  end

  describe "the type keyword test" do
    test "string type matches string" do
      assert :ok = TypeKeyword.type("I'm a string")
    end

    test "string type does not match nonstring" do
      assert {:error, list} = TypeKeyword.type(42)
      assert list[:absolute_keyword_location] == "#/type"
      assert list[:error_value] == 42
      assert list[:instance_location] == "/"
    end
  end

  defmodule JsonSchema do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#declaring-a-json-schema
    """
    require Exonerate

    Exonerate.function_from_string(
      :def,
      :schema,
      ~s({"$schema": "http://json-schema.org/schema#"}),
      metadata: true
    )
  end

  describe "the schema keyword test" do
    test "schema can be retrieved" do
      assert "http://json-schema.org/schema#" = JsonSchema.schema(:schema_id)
    end
  end

  defmodule ID do
    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/basics.html#declaring-a-unique-identifier
    """
    require Exonerate

    Exonerate.function_from_string(
      :def,
      :id,
      ~s({"$id": "http://yourdomain.com/schemas/myschema.json"}),
      metadata: true
    )
  end

  describe "the id keyword test" do
    test "id can be retrieved" do
      assert "http://yourdomain.com/schemas/myschema.json" = ID.id(:id)
    end
  end
end
