defmodule ExonerateTest.MiscTest do
  use ExUnit.Case, async: true

  describe "for the `string` type" do
    test "non-UTF8 string is rejected when no format is set"
    test "non-UTF8 string is accepted when format is `binary`"
  end
end
