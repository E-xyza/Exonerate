defmodule ExonerateTest.Parse.BooleanTest do
  use ExUnit.Case, async: true

  alias Exonerate.Validator

  describe "when a boolean value is parsed" do
    test "it sets boolean to true when true" do
      assert %{boolean: true} = Validator.parse(true, [])
      assert %{boolean: true} = Validator.parse(%{"foo" => true}, ["foo"])
    end

    test "it sets boolean to false when false" do
      assert %{boolean: false} = Validator.parse(false, [])
      assert %{boolean: false} = Validator.parse(%{"foo" => false}, ["foo"])
    end
  end

  describe "when an object value is parsed" do
    test "it leaves the boolean as nil" do
      assert %{boolean: nil} = Validator.parse(%{}, [])
      assert %{boolean: nil} = Validator.parse(%{"foo" => %{}}, ["foo"])
    end
  end
end
