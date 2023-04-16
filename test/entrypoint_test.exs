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

  Exonerate.function_from_string(
    :defp,
    :multi_1,
    """
      {
        "one": {"type": "string"},
        "two": {"type": "integer"}
     }
     """,
     entrypoint: "/one")

  Exonerate.function_from_string(
    :defp,
    :multi_2,
    """
      {
        "one": {"type": "string"},
        "two": {"type": "integer"}
     }
     """,
     entrypoint: "/two")

  test "multi" do
    assert :ok = multi_1("bar")
    assert :ok = multi_2(42)
    assert {:error, _} = multi_1(42)
    assert {:error, _} = multi_2("bar")
  end
end
