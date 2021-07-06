defmodule ExonerateTest.ToolsTest do
  use ExUnit.Case, async: true

  import Exonerate.Tools, only: [is_member: 2]

  test "is_member works" do
    assert is_member(MapSet.new(["foo"]), "foo")
    refute is_member(MapSet.new(["foo"]), "bar")
  end
end
