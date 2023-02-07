defmodule ExonerateTest.Parse.TypeTest do
  use ExUnit.Case, async: true

  alias Exonerate.Context
  alias Exonerate.Type
  alias Exonerate.Type.Number
  alias Exonerate.Type.String

  describe "when no type filter is present" do
    test "the types are still all the types" do
      assert %Context{types: types} = Context.parse(%{}, [])
      assert Map.keys(types) == Map.keys(Type.all())
    end
  end

  describe "when a type filter is present" do
    test "a single type restricts the types" do
      assert %Context{types: %{String => _}} = Context.parse(%{"type" => "string"}, [])

      assert %Context{types: %{Number => _}} = Context.parse(%{"type" => "number"}, [])
    end

    test "multiple types restrict the types" do
      assert %Context{types: %{Number => _, String => _}} =
               Context.parse(%{"type" => ["string", "number"]}, [])
    end
  end
end
