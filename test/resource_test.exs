defmodule ExonerateTest.ResourceTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.register_resource(
    ~s({"foo": {"type": "string"}}),
    "foo"
  )

  Exonerate.function_from_resource(:defp, :resource, "foo", entrypoint: "/foo")

  test "resource" do
    assert :ok = resource("bar")
    assert {:error, _} = resource(42)
  end
end
