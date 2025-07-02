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

  test "ref tracing works through one hop" do
    assert {:error, error} = ref1(%{"bar" => ["baz"]})

    assert [
             absolute_keyword_location: "#/type",
             error_value: ["baz"],
             instance_location: "/bar",
             ref_trace: ["/properties/bar/$ref"]
           ] = Enum.sort(error)
  end
end
