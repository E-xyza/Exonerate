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

    #  Exonerate.function_from_string(
    #    :def,
    #    :with_any_of,
    #    """
    #    {
    #      "type": "array",
    #      "anyOf": [
    #        {"prefixItems": [{"type": "string"}]},
    #        {"prefixItems": [true, {"type": "string"}]}
    #      ],
    #      "unevaluatedItems": {"type": "number"}
    #    }
    #    """
    #  )
    #
    #  test "it works with anyOf" do
    #    # match first
    #    assert :ok = with_any_of(["47", 47])
    #    assert {:error, _} = with_any_of(["42", 42, "42"])
    #
    #    # match second
    #    assert :ok = with_any_of([47, "42", 47])
    #    assert {:error, _} = with_any_of([42, "42", "42"])
    #
    #    # cross evaluation
    #    assert :ok = with_any_of(["47", "47", 47])
    #  end
    #
    #  Exonerate.function_from_string(
    #    :def,
    #    :with_one_of,
    #    """
    #    {
    #      "type": "array",
    #      "oneOf": [
    #        {"prefixItems": [{"type": "string"}]},
    #        {"prefixItems": [true, {"type": "string"}]}
    #      ],
    #      "unevaluatedItems": {"type": "number"}
    #    }
    #    """
    #  )
    #
    #  test "it works with oneOf" do
    #    assert {:error, _} = with_one_of([42, 42])
    #    assert :ok = with_one_of(["47", 47])
    #    assert :ok = with_one_of([47, "47"])
    #
    #    #      cross-evaluation
    #    assert {:error, _} = with_one_of(["47"])
    #    assert {:error, _} = with_one_of(["42", "42"])
    #  end
    #
    #  # note it's not necessary for unevaluatedProperties to work with "not"
    #
    #  Exonerate.function_from_string(
    #    :def,
    #    :with_if,
    #    """
    #    {
    #      "type": "array",
    #      "if": {"prefixItems": [{"type": "integer"}]},
    #      "then": {"prefixItems": [true, {"type": "integer"}]},
    #      "else": {"prefixItems": [true, {"type": "string"}]},
    #      "unevaluatedItems": {"type": "integer"}
    #    }
    #    """
    #  )
    #
    #  test "it works with if" do
    #    # if clause passes, then clause passes
    #    assert {:error, _} = with_if([42, 42, "42"])
    #    assert :ok = with_if([47, 47, 47])
    #    # if clause fails, then clause passes
    #    assert {:error, _} = with_if(["42", "42", "42"])
    #    assert :ok = with_if(["47", "47", 47])
    #  end
  end
end
