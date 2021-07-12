defmodule ExonerateTest.Parse.TypeTest do
  use ExUnit.Case, async: true

  alias Exonerate.Validator
  alias Exonerate.Type
  alias Exonerate.Type.Number
  alias Exonerate.Type.String

  describe "when no type filter is present" do
    test "the types are still all the types" do
      assert %Validator{types: types} = Validator.parse(%{}, [])
      assert Map.keys(types) == Map.keys(Type.all())
    end
  end

  describe "when a type filter is present" do
    test "a single type restricts the types" do
      assert %Validator{types: %{String => _}} = Validator.parse(%{"type" => "string"}, [])

      assert %Validator{types: %{Number => _}} = Validator.parse(%{"type" => "number"}, [])
    end

    test "multiple types restrict the types" do
      assert %Validator{types: %{Number => _, String => _}} = Validator.parse(%{"type" => ["string", "number"]}, [])
    end
  end
end
