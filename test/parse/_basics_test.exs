defmodule ExonerateTest.Parse.BasicsTest do
  use ExUnit.Case, async: true

  alias Exonerate.Validator

  describe "when you send a path" do
    test "it gets saved as the 'pointer' key" do
      assert %{pointer: []} = Validator.parse(%{}, [])
      assert %{pointer: ["foo"]} =
        Validator.parse(%{"foo" => %{"type" => "integer"}}, ["foo"])
    end

    test "if raises if the path is not traversible" do
      assert_raise KeyError, fn ->
        Validator.parse(%{}, ["foo"])
      end

      assert_raise ArgumentError, fn ->
        Validator.parse([%{}], ["foo"])
      end
    end
  end

  describe "when a value is parsed" do
    test "it gets saved as the schema" do
      assert %{schema: %{}} = Validator.parse(%{}, [])
      assert %{schema: %{"type" => "integer"}} = Validator.parse(%{"type" => "integer"}, [])
    end

    test "it raises if it's not a boolean or an object" do
      assert_raise ArgumentError, fn ->
        Validator.parse("foo", [])
      end

      assert_raise ArgumentError, fn ->
        Validator.parse(:foo, [])
      end

      assert_raise ArgumentError, fn ->
        Validator.parse(["foo"], [])
      end
    end
  end
end
