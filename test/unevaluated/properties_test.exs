defmodule ExonerateTest.Unevaluated.PropertiesTest do
  use ExUnit.Case

  require Exonerate

  Exonerate.function_from_string(
    :def,
    :with_properties,
    """
    {
      "type": "object",
      "properties": {"foo": {"type": "string"}},
      "unevaluatedProperties": {"type": "number"}
    }
    """
  )

  test "with properties" do
    assert {:error, _} = with_properties(%{"foo" => 42})
    assert :ok = with_properties(%{"foo" => "bar"})
    assert :ok = with_properties(%{"foo" => "bar", "baz" => 47})
    assert {:error, _} = with_properties(%{"foo" => "bar", "baz" => "quux"})
  end
end
