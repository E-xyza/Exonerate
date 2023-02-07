defmodule ExonerateTest.Parse.BooleanTest do
  use ExUnit.Case, async: true

  alias Exonerate.Context

  describe "when a boolean value is parsed" do
    test "it sets boolean to true when true" do
      assert %Context{} = Context.parse(true, [])
      assert %Context{} = Context.parse(%{"foo" => true}, ["foo"])
    end

    test "it sets boolean to false when false" do
      assert %Context{} = Context.parse(false, [])
      assert %Context{} = Context.parse(%{"foo" => false}, ["foo"])
    end
  end

  describe "when an object value is parsed" do
    test "it leaves the boolean as nil" do
      assert %Context{} = Context.parse(%{}, [])
      assert %Context{} = Context.parse(%{"foo" => %{}}, ["foo"])
    end
  end
end
