defmodule ExonerateTest.FunctionFromFileTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_file(:def, :foo, "test/assets/basic.json")

  test "foo" do
    assert :ok = foo("bar")
    assert :ok = foo(42)
    assert {:error, _} = foo(%{})
    assert {:error, _} = foo([])
  end

  Exonerate.function_from_file(
    :def,
    :bar,
    "test/assets/basic.yaml",
    decoder: {YamlElixir, :read_from_string!}
  )

  test "bar" do
    assert :ok = bar("bar")
    assert {:error, _} = bar(42)
  end
end
