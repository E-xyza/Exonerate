defmodule ExonerateTest.RefTraceTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(:defp, :ref1, """
  {
    "properties": {
        "foo": {"type": "integer"},
        "bar": {"$ref": "#/properties/foo"}
    }
  }
  """)

  test "ref tracing works through one hop" do
    assert {:error, [
      ref_trace: ["/properties/bar"],
      schema_pointer: "/properties/foo/type",
      error_value: "baz",
      json_pointer: "/bar"
    ]} = ref1(%{"bar" => "baz"})
  end

  Exonerate.function_from_string(:defp, :ref2, """
  {
    "properties": {
        "foo": {"type": "integer"},
        "bar": {"$ref": "#/properties/foo"},
        "baz": {"$ref": "#/properties/bar"}
    }
  }
  """)

  test "ref tracing works through two hops" do
    assert {:error, [
      ref_trace: ["/properties/baz", "/properties/bar"],
      schema_pointer: "/properties/foo/type",
      error_value: "quux",
      json_pointer: "/baz"
    ]} = ref2(%{"baz" => "quux"})
  end
end
