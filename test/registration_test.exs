defmodule ExonerateTest.RegistrationTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.register_resource(
    """
    {"schema": {"type": "integer"}}
    """,
    "foo-resource"
  )

  Exonerate.function_from_resource(:def, :indirect, "foo-resource", entrypoint: "/schema")

  describe "registered schema" do
    test "works with entrypoint" do
      assert :ok = indirect(47)
      assert {:error, _} = indirect("42")
    end
  end
end
