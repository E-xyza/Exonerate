defmodule ExonerateTest.Parse.NumberTest do
  use ExUnit.Case, async: true

  alias Exonerate.Filter.{ExclusiveMaximum, ExclusiveMinimum, Maximum, Minimum, MultipleOf}
  alias Exonerate.Type.Number

  @validator %Exonerate.Validator{pointer: [], schema: %{}, authority: ""}

  describe "range parameters are set" do
    test "maximum" do
      assert %{
               filters: [%Maximum{maximum: 3}]
             } = Number.parse(@validator, %{"maximum" => 3})
    end

    test "minimum" do
      assert %{
               filters: [%Minimum{minimum: 3}]
             } = Number.parse(@validator, %{"minimum" => 3})
    end

    test "exclusiveMaximum" do
      assert %{
               filters: [%ExclusiveMaximum{maximum: 3}]
             } = Number.parse(@validator, %{"exclusiveMaximum" => 3})
    end

    test "exclusiveMinimum" do
      assert %{
               filters: [%ExclusiveMinimum{minimum: 3}]
             } = Number.parse(@validator, %{"exclusiveMinimum" => 3})
    end
  end

  describe "multipleOf parameters is not set" do
    test "correctly" do
      assert %{
               filters: [%MultipleOf{}]
             } = Number.parse(@validator, %{"multipleOf" => 3})
    end
  end
end
