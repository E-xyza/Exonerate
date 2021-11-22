defmodule ExonerateTest.RequiredTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(:def, :required_0, ~s({"required": ["foo"]}))
  Exonerate.function_from_string(:def, :required_1, ~s({"properties": {"foo": {"required": ["foo"]}}}))

  test "required outputs the missing field" do
    assert {:error, msg} = required_0(%{})
    assert Keyword.get(msg, :required) == "/foo"
  end

  test "required works to give correct results when nested" do
    assert {:error, msg} = required_1(%{"foo" => %{}})
    assert Keyword.get(msg, :required) == "/foo/foo"
  end

end
