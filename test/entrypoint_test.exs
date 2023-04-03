defmodule ExonerateTest.EntrypointTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(
    :defp,
    :foo,
    ~s({"foo" : {"bar" : {"type": "string"}}}),
    entrypoint: "/foo/bar"
  )

  test "foo" do
    assert :ok = foo("bar")
    assert {:error, _} = foo(42)
  end
end
