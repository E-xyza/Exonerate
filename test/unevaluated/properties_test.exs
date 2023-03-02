defmodule ExonerateTest.Unevaluated.PropertiesTest do
  use ExUnit.Case, async: true
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
      :with_properties_false,
      """
      {
        "type": "object",
        "properties": {"foo": {"type": "string"}},
        "unevaluatedProperties": false
      }
      """
    )

    test "with properties, but false" do
      assert :ok = with_properties_false(%{})
      assert :ok = with_properties_false(%{"foo" => "bar"})
      assert {:error, _} = with_properties_false(%{"foo" => "bar", "baz" => "quux"})
      assert {:error, _} = with_properties_false(%{"baz" => "quux"})
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
      assert {:error, _} = with_any_of(%{"foo" => "bar", "baz" => "42"})
      assert :ok = with_any_of(%{"foo" => "bar", "baz" => 47})
      assert {:error, _} = with_any_of(%{"bar" => true, "baz" => "42"})
      assert :ok = with_any_of(%{"bar" => true, "baz" => 47})
      assert {:error, _} = with_any_of(%{"foo" => "bar", "bar" => true, "baz" => "42"})
      assert :ok = with_any_of(%{"foo" => "bar", "bar" => true, "baz" => 47})

      # cross evaluation
      assert {:error, _} = with_any_of(%{"foo" => "bar", "bar" => "42"})
      assert :ok = with_any_of(%{"foo" => "bar", "bar" => 47})
      assert {:error, _} = with_any_of(%{"foo" => true, "bar" => true})
      assert :ok = with_any_of(%{"foo" => 47, "bar" => true})
    end

    Exonerate.function_from_string(
      :def,
      :with_one_of,
      """
      {
        "type": "object",
        "oneOf": [
          {"properties": {"foo": {"type": "string"}}, "required": ["foo"]},
          {"properties": {"bar": {"type": "boolean"}}, "required": ["bar"]}
        ],
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "it works with oneOf" do
      assert {:error, _} = with_one_of(%{"foo" => "bar", "baz" => "42"})
      assert :ok = with_one_of(%{"foo" => "bar", "baz" => 47})
      assert {:error, _} = with_one_of(%{"bar" => true, "baz" => "42"})
      assert :ok = with_one_of(%{"bar" => true, "baz" => 47})

      #      cross-evaluation
      assert {:error, _} = with_one_of(%{"foo" => "bar", "bar" => "42"})
      assert :ok = with_one_of(%{"foo" => "bar", "bar" => 47})

      assert {:error, _} = with_one_of(%{"foo" => "42", "bar" => true})
      assert :ok = with_one_of(%{"foo" => 47, "bar" => true})
    end

    # note it's not necessary for unevaluatedProperties to work with "not"

    Exonerate.function_from_string(
      :def,
      :with_if,
      """
      {
        "type": "object",
        "if": {"properties": {"foo": {"type": "string"}}, "required": ["foo"]},
        "then": {"properties": {"bar": {"type": "boolean"}}, "required": ["bar"]},
        "else": {"properties": {"baz": {"type": "string"}}, "required": ["baz"]},
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "it works with if" do
      assert {:error, _} = with_if(%{"foo" => "bar", "bar" => true, "baz" => "42"})
      assert :ok = with_if(%{"foo" => "bar", "bar" => true, "baz" => 47})
      assert {:error, _} = with_if(%{"bar" => "42", "baz" => "42"})
      assert :ok = with_if(%{"bar" => 47, "baz" => "47"})
    end
  end

  describe "automated test regressions" do
    Exonerate.function_from_string(
      :def,
      :nested_outer_false_inner_true,
      """
      {
          "type": "object",
          "properties": {
              "foo": { "type": "string" }
          },
          "allOf": [
              {
                  "unevaluatedProperties": true
              }
          ],
          "unevaluatedProperties": false
      }
      """
    )

    test "nested, outer false, inner true" do
      assert :ok = nested_outer_false_inner_true(%{"foo" => "foo", "bar" => "bar"})
    end
  end
end
