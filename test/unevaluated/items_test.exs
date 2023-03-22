defmodule ExonerateTest.Unevaluated.ItemsTest do
  use ExUnit.Case, async: true
  require Exonerate

  describe "when as part of a primary operation" do
    Exonerate.function_from_string(
      :def,
      :with_items,
      """
      {
        "type": "array",
        "prefixItems": [{"type": "string"}],
        "unevaluatedItems": {"type": "number"}
      }
      """
    )

    test "with items" do
      assert {:error, _} = with_items([42])
      assert :ok = with_items(["47"])
      assert :ok = with_items(["47", 47])
      assert {:error, _} = with_items(["42", "42"])
    end

    Exonerate.function_from_string(
      :def,
      :with_prefix_items_false,
      """
      {
        "type": "array",
        "prefixItems": [{"type": "string"}],
        "unevaluatedItems": false
      }
      """
    )

    test "with items, but false" do
      assert :ok = with_prefix_items_false([])
      assert :ok = with_prefix_items_false(["47"])
      assert {:error, _} = with_prefix_items_false(["42", 42])
      assert {:error, _} = with_prefix_items_false(["42", "42"])
    end
  end

  describe "when used with in-place combiners" do
    Exonerate.function_from_string(
      :def,
      :with_all_of,
      """
      {
        "type": "array",
        "allOf": [
          {"prefixItems": [{"type": "string"}]},
          {"prefixItems": [true, true]}
        ],
        "unevaluatedItems": {"type": "number"}
      }
      """
    )

    test "it works with allOf" do
      assert {:error, _} = with_all_of(["42", 42, "42"])
      assert :ok = with_all_of(["47", 47, 47])
    end

    Exonerate.function_from_string(
      :def,
      :with_any_of,
      """
      {
        "type": "object",
        "anyOf": [
          {"prefixItems": [{"type": "string"}]},
          {"prefixItems": [true, {"type": "string"}]}
        ],
        "unevaluatedProperties": {"type": "number"}
      }
      """
    )

    test "it works with anyOf" do
      # match first
      assert :ok = with_any_of(["47", 47])
      assert {:error, _} = with_any_of(["42", 42, "42"])

      # match second
      assert :ok = with_any_of([47, "42", 47])
      assert {:error, _} = with_any_of([42, "42", "42"])

      # cross evaluation
      assert :ok = with_any_of(["47", "47", 47])
    end

    #    Exonerate.function_from_string(
    #      :def,
    #      :with_one_of,
    #      """
    #      {
    #        "type": "object",
    #        "oneOf": [
    #          {"properties": {"foo": {"type": "string"}}, "required": ["foo"]},
    #          {"properties": {"bar": {"type": "boolean"}}, "required": ["bar"]}
    #        ],
    #        "unevaluatedProperties": {"type": "number"}
    #      }
    #      """
    #    )
    #
    #    test "it works with oneOf" do
    #      assert {:error, _} = with_one_of(%{"foo" => "bar", "baz" => "42"})
    #      assert :ok = with_one_of(%{"foo" => "bar", "baz" => 47})
    #      assert {:error, _} = with_one_of(%{"bar" => true, "baz" => "42"})
    #      assert :ok = with_one_of(%{"bar" => true, "baz" => 47})
    #
    #      #      cross-evaluation
    #      assert {:error, _} = with_one_of(%{"foo" => "bar", "bar" => "42"})
    #      assert :ok = with_one_of(%{"foo" => "bar", "bar" => 47})
    #
    #      assert {:error, _} = with_one_of(%{"foo" => "42", "bar" => true})
    #      assert :ok = with_one_of(%{"foo" => 47, "bar" => true})
    #    end
    #
    #    # note it's not necessary for unevaluatedProperties to work with "not"
    #
    #    Exonerate.function_from_string(
    #      :def,
    #      :with_if,
    #      """
    #      {
    #        "type": "object",
    #        "if": {"properties": {"foo": {"type": "string"}}, "required": ["foo"]},
    #        "then": {"properties": {"bar": {"type": "boolean"}}, "required": ["bar"]},
    #        "else": {"properties": {"baz": {"type": "string"}}, "required": ["baz"]},
    #        "unevaluatedProperties": {"type": "number"}
    #      }
    #      """
    #    )
    #
    #    test "it works with if" do
    #      assert {:error, _} = with_if(%{"foo" => "bar", "bar" => true, "baz" => "42"})
    #      assert :ok = with_if(%{"foo" => "bar", "bar" => true, "baz" => 47})
    #      assert {:error, _} = with_if(%{"bar" => "42", "baz" => "42"})
    #      assert :ok = with_if(%{"bar" => 47, "baz" => "47"})
    #    end
    #  end
    #
  end
end
