defmodule ExonerateTest.Unevaluated.PropertiesTest do
  use ExUnit.Case
  require Exonerate

  describe "when as part of a primary operation" do
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

    Exonerate.function_from_string(
      :def,
      :with_pattern_properties,
      """
      {
        "type": "object",
        "patternProperties": {"^S_": {"type": "string"}},
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "with patternProperties" do
      assert {:error, _} = with_pattern_properties(%{"S_1" => 47})
      assert :ok = with_pattern_properties(%{"S_1" => "foo"})
      assert :ok = with_pattern_properties(%{"S_1" => "foo", "bar" => 47})
      assert {:error, _} = with_pattern_properties(%{"S_1" => "foo", "bar" => "baz"})
    end

    Exonerate.function_from_string(
      :def,
      :with_additional_properties,
      """
      {
        "type": "object",
        "additionalProperties": {"type": "string"},
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    # note that unevaluatedProperties will never trigger.
    test "with additionalProperties" do
      assert {:error, _} = with_additional_properties(%{"foo" => 47})
      assert :ok = with_additional_properties(%{"foo" => "bar"})
    end
  end

  describe "when used with in-place combiners" do
    Exonerate.function_from_string(
      :def,
      :with_all_of,
      """
      {
        "type": "object",
        "allOf": [
          {"properties": {"foo": {"type": "string"}}},
          {"properties": {"bar": {"type": "boolean"}}}
        ],
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "it works with allOf" do
      assert {:error, _} = with_all_of(%{"foo" => "bar", "bar" => true, "baz" => "42"})
      assert :ok = with_all_of(%{"foo" => "bar", "bar" => true, "baz" => 47})
    end

    Exonerate.function_from_string(
      :def,
      :with_any_of,
      """
      {
        "type": "object",
        "anyOf": [
          {"properties": {"foo": {"type": "string"}}},
          {"properties": {"bar": {"type": "boolean"}}}
        ],
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "it works with anyOf" do
      assert {:error, _} = with_all_of(%{"foo" => "bar", "baz" => "42"})
      assert :ok = with_all_of(%{"foo" => "bar", "baz" => 47})
      assert {:error, _} = with_all_of(%{"bar" => true, "baz" => "42"})
      assert :ok = with_all_of(%{"bar" => true, "baz" => 47})
      assert {:error, _} = with_all_of(%{"foo" => "bar", "bar" => true, "baz" => "42"})
      assert :ok = with_all_of(%{"foo" => "bar", "bar" => true, "baz" => 47})
    end

    test "it works with oneOf"

    # note it's not necessary for unevaluatedProperties to work with "not"

    test "it works with if"
  end
end
