defmodule ExonerateTest.RegressionTest do
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
end
