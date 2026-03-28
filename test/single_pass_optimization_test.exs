defmodule ExonerateTest.SinglePassOptimizationTest do
  @moduledoc """
  Tests verifying that the single-pass optimization is correctly applied.
  """
  use ExUnit.Case, async: true

  require Exonerate

  # This schema should trigger optimization:
  # - Has 2+ property-only sub-schemas
  # - No extra filters in sub-schemas
  describe "optimization triggers for allOf with property-only sub-schemas" do
    Exonerate.function_from_string(
      :def,
      :optimized_allof,
      """
      {
        "type": "object",
        "allOf": [
          {"properties": {"a": {"type": "string"}}},
          {"properties": {"b": {"type": "integer"}}},
          {"properties": {"c": {"type": "boolean"}}}
        ]
      }
      """
    )

    test "validates all properties" do
      assert :ok = optimized_allof(%{"a" => "x", "b" => 1, "c" => true})
    end

    test "validates with missing properties" do
      assert :ok = optimized_allof(%{"a" => "x"})
      assert :ok = optimized_allof(%{"b" => 1})
      assert :ok = optimized_allof(%{})
    end

    test "rejects invalid property types" do
      assert {:error, error} = optimized_allof(%{"a" => 123})
      assert error[:absolute_keyword_location] =~ "allOf/0/properties/a/type"
    end
  end

  # This schema should NOT trigger optimization:
  # - Sub-schemas have additional filters (required)
  describe "no optimization for allOf with non-property-only sub-schemas" do
    Exonerate.function_from_string(
      :def,
      :not_optimized_allof,
      """
      {
        "type": "object",
        "allOf": [
          {
            "properties": {"a": {"type": "string"}},
            "required": ["a"]
          },
          {
            "properties": {"b": {"type": "integer"}},
            "minProperties": 1
          }
        ]
      }
      """
    )

    test "validates with all required" do
      assert :ok = not_optimized_allof(%{"a" => "x", "b" => 1})
    end

    test "rejects missing required" do
      assert {:error, _} = not_optimized_allof(%{"b" => 1})
    end
  end

  # Mixed optimization - some sub-schemas can be merged, others cannot
  describe "partial optimization for mixed sub-schemas" do
    Exonerate.function_from_string(
      :def,
      :partial_optimized_allof,
      """
      {
        "type": "object",
        "allOf": [
          {"properties": {"a": {"type": "string"}}},
          {"properties": {"b": {"type": "integer"}}},
          {
            "properties": {"c": {"type": "boolean"}},
            "required": ["c"]
          }
        ]
      }
      """
    )

    test "validates with all properties" do
      assert :ok = partial_optimized_allof(%{"a" => "x", "b" => 1, "c" => true})
    end

    test "rejects missing required" do
      assert {:error, _} = partial_optimized_allof(%{"a" => "x", "b" => 1})
    end
  end

  # Test that error locations are preserved correctly
  describe "error location preservation" do
    Exonerate.function_from_string(
      :def,
      :error_location_test,
      """
      {
        "type": "object",
        "allOf": [
          {"properties": {"x": {"type": "string", "minLength": 3}}},
          {"properties": {"y": {"type": "integer", "minimum": 10}}}
        ]
      }
      """
    )

    test "reports correct error location for string constraint" do
      assert {:error, error} = error_location_test(%{"x" => "ab"})
      assert error[:absolute_keyword_location] =~ "allOf/0/properties/x/minLength"
    end

    test "reports correct error location for integer constraint" do
      assert {:error, error} = error_location_test(%{"y" => 5})
      assert error[:absolute_keyword_location] =~ "allOf/1/properties/y/minimum"
    end
  end

  # Test with unevaluatedProperties (tracked mode)
  describe "optimization with unevaluatedProperties" do
    Exonerate.function_from_string(
      :def,
      :optimized_unevaluated,
      """
      {
        "type": "object",
        "allOf": [
          {"properties": {"a": {"type": "string"}}},
          {"properties": {"b": {"type": "integer"}}}
        ],
        "unevaluatedProperties": false
      }
      """
    )

    test "allows known properties" do
      assert :ok = optimized_unevaluated(%{"a" => "x", "b" => 1})
    end

    test "rejects unknown properties" do
      assert {:error, _} = optimized_unevaluated(%{"a" => "x", "c" => "extra"})
    end
  end
end
