defmodule ExonerateTest.RelativeRefTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(
    :defp,
    :ref1,
    """
    {
      "properties": {
          "foo": {"type": "integer"},
          "bar": {"$ref": "./test/assets/basic.json"}
      }
    }
    """
  )

  test "relative ref works with ./ prefix" do
    assert {:error, error} = ref1(%{"bar" => ["baz"]})

    assert [
             absolute_keyword_location: "#/type",
             error_value: ["baz"],
             expected: ["integer", "string"],
             instance_location: "/bar",
             ref_trace: ["/properties/bar/$ref"]
           ] = Enum.sort(error)
  end

  # Test relative ref with JSON pointer fragment
  Exonerate.function_from_string(
    :defp,
    :ref_with_fragment,
    """
    {
      "properties": {
        "name": {"$ref": "./test/assets/with_definitions.json#/definitions/name"},
        "age": {"$ref": "./test/assets/with_definitions.json#/definitions/age"}
      }
    }
    """
  )

  test "relative ref works with fragment pointer" do
    # Valid data
    assert :ok = ref_with_fragment(%{"name" => "Alice", "age" => 30})

    # Invalid name (empty string fails minLength)
    assert {:error, error} = ref_with_fragment(%{"name" => ""})
    assert error[:instance_location] == "/name"

    # Invalid age (negative fails minimum)
    assert {:error, error} = ref_with_fragment(%{"age" => -1})
    assert error[:instance_location] == "/age"

    # Invalid name type
    assert {:error, error} = ref_with_fragment(%{"name" => 123})
    assert error[:instance_location] == "/name"
  end
end
