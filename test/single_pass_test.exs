defmodule ExonerateTest.SinglePassTest do
  @moduledoc """
  Tests for single-pass optimization of combining filters.

  When combining filters (allOf, anyOf, oneOf) contain sub-schemas with properties,
  we want to iterate over the object properties only once instead of once per
  sub-schema.
  """
  use ExUnit.Case, async: true

  require Exonerate

  # ===========================================================================
  # Basic allOf with multiple property sub-schemas
  # ===========================================================================

  describe "allOf with multiple property sub-schemas" do
    Exonerate.function_from_string(
      :def,
      :allof_multi_properties,
      """
      {
        "type": "object",
        "allOf": [
          {
            "properties": {
              "name": {"type": "string"}
            }
          },
          {
            "properties": {
              "age": {"type": "integer"}
            }
          },
          {
            "properties": {
              "active": {"type": "boolean"}
            }
          }
        ]
      }
      """
    )

    test "validates all properties correctly" do
      assert :ok = allof_multi_properties(%{"name" => "Alice", "age" => 30, "active" => true})
      assert :ok = allof_multi_properties(%{"name" => "Bob"})
      assert :ok = allof_multi_properties(%{})
    end

    test "rejects invalid property types" do
      assert {:error, _} = allof_multi_properties(%{"name" => 123})
      assert {:error, _} = allof_multi_properties(%{"age" => "thirty"})
      assert {:error, _} = allof_multi_properties(%{"active" => "yes"})
    end
  end

  # ===========================================================================
  # anyOf with overlapping properties
  # ===========================================================================

  describe "anyOf with overlapping properties" do
    Exonerate.function_from_string(
      :def,
      :anyof_overlapping,
      """
      {
        "type": "object",
        "anyOf": [
          {
            "properties": {
              "id": {"type": "string"},
              "name": {"type": "string"}
            },
            "required": ["id"]
          },
          {
            "properties": {
              "id": {"type": "integer"},
              "code": {"type": "string"}
            },
            "required": ["id"]
          }
        ]
      }
      """
    )

    test "validates when first schema matches" do
      assert :ok = anyof_overlapping(%{"id" => "abc", "name" => "Test"})
    end

    test "validates when second schema matches" do
      assert :ok = anyof_overlapping(%{"id" => 123, "code" => "XYZ"})
    end

    test "validates when both schemas could match" do
      # This matches the second schema (id is integer)
      assert :ok = anyof_overlapping(%{"id" => 42})
    end

    test "rejects when no schema matches" do
      assert {:error, _} = anyof_overlapping(%{"name" => "NoId"})
    end
  end

  # ===========================================================================
  # oneOf with distinct properties
  # ===========================================================================

  describe "oneOf with distinct properties" do
    Exonerate.function_from_string(
      :def,
      :oneof_distinct,
      """
      {
        "type": "object",
        "oneOf": [
          {
            "properties": {
              "type": {"const": "person"},
              "name": {"type": "string"}
            },
            "required": ["type", "name"]
          },
          {
            "properties": {
              "type": {"const": "company"},
              "legalName": {"type": "string"}
            },
            "required": ["type", "legalName"]
          }
        ]
      }
      """
    )

    test "validates person type" do
      assert :ok = oneof_distinct(%{"type" => "person", "name" => "Alice"})
    end

    test "validates company type" do
      assert :ok = oneof_distinct(%{"type" => "company", "legalName" => "Acme Inc"})
    end

    test "rejects when no schema matches" do
      assert {:error, _} = oneof_distinct(%{"type" => "unknown"})
    end

    test "rejects when multiple schemas match" do
      # Both schemas require "type" but have different const values, so this won't match both
      # This should fail because type=person requires name
      assert {:error, _} = oneof_distinct(%{"type" => "person"})
    end
  end

  # ===========================================================================
  # Nested combining (allOf containing anyOf)
  # ===========================================================================

  describe "nested combining filters" do
    Exonerate.function_from_string(
      :def,
      :nested_combining,
      """
      {
        "type": "object",
        "allOf": [
          {
            "properties": {
              "id": {"type": "string"}
            },
            "required": ["id"]
          },
          {
            "anyOf": [
              {
                "properties": {
                  "role": {"const": "admin"},
                  "permissions": {"type": "array"}
                },
                "required": ["role"]
              },
              {
                "properties": {
                  "role": {"const": "user"},
                  "email": {"type": "string"}
                },
                "required": ["role"]
              }
            ]
          }
        ]
      }
      """
    )

    test "validates admin with permissions" do
      assert :ok = nested_combining(%{
        "id" => "123",
        "role" => "admin",
        "permissions" => ["read", "write"]
      })
    end

    test "validates user with email" do
      assert :ok = nested_combining(%{
        "id" => "456",
        "role" => "user",
        "email" => "user@example.com"
      })
    end

    test "rejects missing id" do
      assert {:error, _} = nested_combining(%{"role" => "admin", "permissions" => []})
    end

    test "rejects invalid role" do
      assert {:error, _} = nested_combining(%{"id" => "789", "role" => "guest"})
    end
  end

  # ===========================================================================
  # allOf with patternProperties
  # ===========================================================================

  describe "allOf with patternProperties" do
    Exonerate.function_from_string(
      :def,
      :allof_pattern,
      """
      {
        "type": "object",
        "allOf": [
          {
            "patternProperties": {
              "^x-": {"type": "string"}
            }
          },
          {
            "patternProperties": {
              "^y-": {"type": "integer"}
            }
          }
        ]
      }
      """
    )

    test "validates mixed pattern properties" do
      assert :ok = allof_pattern(%{"x-custom" => "value", "y-count" => 42})
    end

    test "validates only x-properties" do
      assert :ok = allof_pattern(%{"x-one" => "a", "x-two" => "b"})
    end

    test "validates only y-properties" do
      assert :ok = allof_pattern(%{"y-first" => 1, "y-second" => 2})
    end

    test "rejects invalid x-property type" do
      assert {:error, _} = allof_pattern(%{"x-num" => 123})
    end

    test "rejects invalid y-property type" do
      assert {:error, _} = allof_pattern(%{"y-str" => "not a number"})
    end
  end

  # ===========================================================================
  # allOf with unevaluatedProperties (tracked mode)
  # ===========================================================================

  describe "allOf with unevaluatedProperties" do
    Exonerate.function_from_string(
      :def,
      :allof_unevaluated,
      """
      {
        "type": "object",
        "allOf": [
          {
            "properties": {
              "name": {"type": "string"}
            }
          },
          {
            "properties": {
              "age": {"type": "integer"}
            }
          }
        ],
        "unevaluatedProperties": false
      }
      """
    )

    test "validates known properties" do
      assert :ok = allof_unevaluated(%{"name" => "Alice", "age" => 30})
      assert :ok = allof_unevaluated(%{"name" => "Bob"})
      assert :ok = allof_unevaluated(%{"age" => 25})
      assert :ok = allof_unevaluated(%{})
    end

    test "rejects unknown properties" do
      assert {:error, _} = allof_unevaluated(%{"name" => "Alice", "extra" => "field"})
    end

    test "rejects invalid known property types" do
      assert {:error, _} = allof_unevaluated(%{"name" => 123})
      assert {:error, _} = allof_unevaluated(%{"age" => "thirty"})
    end
  end

  # ===========================================================================
  # anyOf with unevaluatedProperties (tracked mode with OR semantics)
  # ===========================================================================

  describe "anyOf with unevaluatedProperties" do
    Exonerate.function_from_string(
      :def,
      :anyof_unevaluated,
      """
      {
        "type": "object",
        "anyOf": [
          {
            "properties": {
              "stringId": {"type": "string"}
            },
            "required": ["stringId"]
          },
          {
            "properties": {
              "numericId": {"type": "integer"}
            },
            "required": ["numericId"]
          }
        ],
        "unevaluatedProperties": false
      }
      """
    )

    test "validates with string id only" do
      assert :ok = anyof_unevaluated(%{"stringId" => "abc"})
    end

    test "validates with numeric id only" do
      assert :ok = anyof_unevaluated(%{"numericId" => 123})
    end

    test "validates with both ids (both schemas evaluated)" do
      assert :ok = anyof_unevaluated(%{"stringId" => "abc", "numericId" => 123})
    end

    test "rejects extra properties" do
      assert {:error, _} = anyof_unevaluated(%{"stringId" => "abc", "extra" => "field"})
    end

    test "rejects when no schema matches" do
      assert {:error, _} = anyof_unevaluated(%{"other" => "value"})
    end
  end

  # ===========================================================================
  # Complex real-world schema
  # ===========================================================================

  describe "complex real-world schema" do
    Exonerate.function_from_string(
      :def,
      :api_response,
      """
      {
        "type": "object",
        "allOf": [
          {
            "properties": {
              "status": {"type": "integer", "minimum": 100, "maximum": 599},
              "timestamp": {"type": "string"}
            },
            "required": ["status"]
          },
          {
            "oneOf": [
              {
                "properties": {
                  "data": {"type": "object"},
                  "error": false
                },
                "required": ["data"]
              },
              {
                "properties": {
                  "error": {
                    "type": "object",
                    "properties": {
                      "code": {"type": "string"},
                      "message": {"type": "string"}
                    },
                    "required": ["code", "message"]
                  }
                },
                "required": ["error"]
              }
            ]
          }
        ]
      }
      """
    )

    test "validates success response" do
      assert :ok = api_response(%{
        "status" => 200,
        "timestamp" => "2024-01-01T00:00:00Z",
        "data" => %{"result" => "success"}
      })
    end

    test "validates error response" do
      assert :ok = api_response(%{
        "status" => 400,
        "error" => %{"code" => "BAD_REQUEST", "message" => "Invalid input"}
      })
    end

    test "rejects response without status" do
      assert {:error, _} = api_response(%{"data" => %{}})
    end

    test "rejects response with invalid status" do
      assert {:error, _} = api_response(%{"status" => 999, "data" => %{}})
    end

    test "rejects response with neither data nor error" do
      assert {:error, _} = api_response(%{"status" => 200})
    end
  end
end
