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
end
