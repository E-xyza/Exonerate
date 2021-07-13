defmodule ExonerateTest.MiscTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(:def, :utf8_string, ~s({"type": "string"}))
  Exonerate.function_from_string(:def, :non_utf8_string, ~s({"type": "string", "format": "binary"}))

  describe "for the `string` type" do
    test "non-UTF8 string is rejected when no format is set" do
      assert :ok == utf8_string("foo 🐛")
      assert {:error, _} = utf8_string(<<255>>)
    end

    test "non-UTF8 string is accepted when format is `binary`" do
      assert :ok == non_utf8_string("foo 🐛")
      assert :ok == non_utf8_string(<<255>>)
    end

    test "string minLength and maxLength are interpreted as bytes when `binary`"
  end
end
