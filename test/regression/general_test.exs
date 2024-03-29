defmodule ExonerateTest.Regression.GeneralTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(:def, :regression, """
  {
    "type": "array",
    "prefixItems": [
      { "type": "integer" },
      { "type": "string" }
    ],
    "items": {"type": "integer"}
  }
  """)

  test "regression passes" do
    assert :ok = regression([1, "foo", 2, 3])
  end

  # regression identified by @paulswartz
  # id's get annotated when they are properties terms.

  Exonerate.function_from_string(:def, :id_0, ~s({"properties": {"id": {"type": "number"}}}))

  Exonerate.function_from_string(
    :def,
    :id_1,
    ~s({"properties": {"object": {"type": "object", "properties": {"id": {"type": "number"}}}}})
  )

  describe "top-level id property" do
    test "number is valid" do
      assert :ok = id_0(%{"id" => 1})
    end

    test "string is not valid" do
      assert {:error, msg} = id_0(%{"id" => "value"})
      assert Keyword.get(msg, :instance_location) == "/id"
    end
  end

  describe "nested id property" do
    test "number is valid" do
      assert :ok = id_1(%{"object" => %{"id" => 1}})
    end

    test "string is not valid" do
      assert {:error, msg} = id_1(%{"object" => %{"id" => "value"}})
      assert Keyword.get(msg, :instance_location) == "/object/id"
    end
  end
end
