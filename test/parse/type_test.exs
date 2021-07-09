defmodule ExonerateTest.Parse.TypeTest do
  use ExUnit.Case, async: true

  alias Exonerate.Validator
  alias Exonerate.Type
  alias Exonerate.Type.Number
  alias Exonerate.Type.String

  describe "when no type filter is present" do
    test "the types are still all the types" do
      assert %Validator{types: types} = Validator.parse(%{}, [])
      assert types == Type.all()
    end
  end

  describe "when a type filter is present" do
    test "a single type restricts the types" do
      assert %Validator{types: types1} = Validator.parse(%{"type" => "string"}, [])
      assert types1 == MapSet.new([String])

      assert %Validator{types: types2} = Validator.parse(%{"type" => "number"}, [])
      assert types2 == MapSet.new([Number])
    end

    test "multiple types restrict the types" do
      assert %Validator{types: types} = Validator.parse(%{"type" => ["string", "number"]}, [])
      assert types == MapSet.new([String, Number])
    end
  end
end
