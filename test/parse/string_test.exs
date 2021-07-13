defmodule ExonerateTest.Parse.StringTest do
  use ExUnit.Case, async: true

  alias Exonerate.Filter.{MaxLength, MinLength, Pattern}
  alias Exonerate.Type.String

  @validator %Exonerate.Validator{pointer: [], schema: %{}, authority: ""}

  describe "length parameters are set" do
    test "minLength" do
      assert %{
        filters: [%MinLength{length: 3}],
        pipeline: ["#/minLength": []]
      } = String.parse(@validator, %{"minLength" => 3})
    end

    test "maxLength" do
      assert %{
        filters: [%MaxLength{length: 3}],
        pipeline: ["#/maxLength": []]
      } = String.parse(@validator, %{"maxLength" => 3})
    end

    test "when format is binary minLength is a guard" do
      assert %{
        filters: [%MinLength{length: 3}],
        pipeline: []
      } = String.parse(@validator, %{"minLength" => 3, "format" => "binary"})
    end

    test "when format is binary maxLength is a guard" do
      assert %{
        filters: [%MaxLength{length: 3}],
        pipeline: []
      } = String.parse(@validator, %{"maxLength" => 3, "format" => "binary"})
    end
  end

  describe "pattern parameters are set" do
    test "as string" do
      assert %{
        filters: [%Pattern{pattern: "foo"}],
        pipeline: ["#/pattern": []]
      } = String.parse(@validator, %{"pattern" => "foo"})
    end
  end

end
