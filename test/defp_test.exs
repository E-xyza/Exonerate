defmodule ExonerateTest.DefpTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(:defp, :foo, ~s({"type": "string"}))

  test "foo" do
    assert :ok = foo("bar")
    assert {:error, _} = foo(42)
  end

  Exonerate.function_from_string(:defp, :bar, ~s({"type": "string", "default": "bar"}))

  test "bar" do
    assert :ok == bar("bar")
  end

  test "not exported" do
    refute function_exported?(__MODULE__, :foo, 1)
    refute function_exported?(__MODULE__, :bar, 1)
  end
end
