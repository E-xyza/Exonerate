defmodule ExonerateTest.Parse.BooleanTest do
  use ExUnit.Case, async: true

  alias Exonerate.Validator

  describe "when a boolean value is parsed" do
    test "it sets boolean to true when true" do
      assert %Validator{} = Validator.parse(true, [])
      assert %Validator{} = Validator.parse(%{"foo" => true}, ["foo"])
    end

    test "it sets boolean to false when false" do
      assert %Validator{} = Validator.parse(false, [])
      assert %Validator{} = Validator.parse(%{"foo" => false}, ["foo"])
    end
  end

  describe "when an object value is parsed" do
    test "it leaves the boolean as nil" do
      assert %Validator{} = Validator.parse(%{}, [])
      assert %Validator{} = Validator.parse(%{"foo" => %{}}, ["foo"])
    end
  end
end
