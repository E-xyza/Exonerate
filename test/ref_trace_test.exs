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
             absolute_keyword_location: "/properties/foo/type",
             error_value: "baz",
             instance_location: "/bar",
             ref_trace: ["/properties/bar/$ref"]
           ] = Enum.sort(error)
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
    assert {:error, error} = ref2(%{"baz" => "quux"})

    assert [
             absolute_keyword_location: "/properties/foo/type",
             error_value: "quux",
             instance_location: "/baz",
             ref_trace: [
               "/properties/baz/$ref",
               "/properties/bar/$ref"
             ]
           ] = Enum.sort(error)
  end

  test "a ref is okay if it's type-restricted but called from elsewhere"
end
