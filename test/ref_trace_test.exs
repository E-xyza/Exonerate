defmodule ExonerateTest.RefTraceTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(
    :defp,
    :ref1,
    """
    {
      "properties": {
          "foo": {"type": "integer"},
          "bar": {"$ref": "#/properties/foo"}
      }
    }
    """
  )

  test "ref tracing works through one hop" do
    assert {:error, error} = ref1(%{"bar" => "baz"})

    assert [
             error_value: "baz",
             json_pointer: "/bar",
             ref_trace: [ref1: "/properties/bar/$ref"],
             schema_pointer: "/properties/foo/type"
           ] = Enum.sort(error)
  end

  #Exonerate.function_from_string(:defp, :ref2, """
  #{
  #  "properties": {
  #      "foo": {"type": "integer"},
  #      "bar": {"$ref": "#/properties/foo"},
  #      "baz": {"$ref": "#/properties/bar"}
  #  }
  #}
  #""")
#
  #test "ref tracing works through two hops" do
  #  assert {:error, error} = ref2(%{"baz" => "quux"})
#
  #  assert [
  #           error_value: "quux",
  #           json_pointer: "/baz",
  #           ref_trace: [ref2: "/properties/baz/$ref", ref2: "/properties/bar/$ref"],
  #           schema_pointer: "/properties/foo/type"
  #         ] = Enum.sort(error)
  #end
#
  #test "a ref is okay if it's type-restricted but called from elsewhere"
end
