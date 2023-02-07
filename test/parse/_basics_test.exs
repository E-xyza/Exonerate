defmodule ExonerateTest.Parse.BasicsTest do
  use ExUnit.Case, async: true

  alias Exonerate.Context

  describe "when you send a path" do
    test "it gets saved as the 'pointer' key" do
      assert %{pointer: []} = Context.parse(%{}, [])
      assert %{pointer: ["foo"]} = Context.parse(%{"foo" => %{"type" => "integer"}}, ["foo"])
    end

    test "if raises if the path is not traversible" do
      assert_raise ArgumentError, fn ->
        Context.parse(%{}, ["foo"])
      end

      assert_raise ArgumentError, fn ->
        Context.parse([%{}], ["foo"])
      end
    end
  end

  describe "when a value is parsed" do
    test "it gets saved as the schema" do
      assert %{schema: %{}} = Context.parse(%{}, [])
      assert %{schema: %{"type" => "integer"}} = Context.parse(%{"type" => "integer"}, [])
    end

    test "it raises if it's not a boolean or an object" do
      assert_raise ArgumentError, fn ->
        Context.parse("foo", [])
      end

      assert_raise ArgumentError, fn ->
        Context.parse(:foo, [])
      end

      assert_raise ArgumentError, fn ->
        Context.parse(["foo"], [])
      end
    end
  end
end
