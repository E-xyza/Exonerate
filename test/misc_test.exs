defmodule ExonerateTest.MiscTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(:def, :utf8_string, ~s({"type": "string"}))

  Exonerate.function_from_string(
    :def,
    :non_utf8_string,
    ~s({"type": "string", "format": "binary"})
  )

  Exonerate.function_from_string(:def, :utf8_length, """
  {
    "type": "string",
    "minLength": 2,
    "maxLength": 3
  }
  """)

  Exonerate.function_from_string(
    :def,
    :non_utf8_length,
    """
    {
      "type": "string",
      "format": "binary",
      "minLength": 8,
      "maxLength": 12
    }
    """
  )

  describe "for the `string` type" do
    test "non-UTF8 string is rejected when no format is set" do
      assert :ok == utf8_string("foo 🐛")
      assert {:error, _} = utf8_string(<<255>>)
    end

    test "non-UTF8 string is accepted when format is `binary`" do
      assert :ok == non_utf8_string("foo 🐛")
      assert :ok == non_utf8_string(<<255>>)
    end

    test "string minLength and maxLength are interpreted as graphemes when no format is set" do
      assert {:error, _} = utf8_length("🐛")
      assert :ok == utf8_length("🐛🐛")
      assert :ok == utf8_length("🐛🐛🐛")
      assert {:error, _} = utf8_length("🐛🐛🐛🐛")

      assert {:error, _} = utf8_length("a")
      assert :ok == utf8_length("aa")
      assert :ok == utf8_length("aaa")
      assert {:error, _} = utf8_length("aaaa")
    end

    test "string minLength and maxLength are interpreted as bytes when `binary`" do
      assert {:error, _} = non_utf8_length("🐛")
      assert :ok == non_utf8_length("🐛🐛")
      assert :ok == non_utf8_length("🐛🐛🐛")
      assert {:error, _} = non_utf8_length("🐛🐛🐛🐛")

      assert {:error, _} = non_utf8_length("aaaa")
      assert :ok == non_utf8_length("aaaaaaaa")
      assert :ok == non_utf8_length("aaaaaaaaaaaa")
      assert {:error, _} = non_utf8_length("aaaaaaaaaaaaaaaa")
    end
  end

  Exonerate.function_from_string(
    :def,
    :minitems_contains,
    """
    {
      "minItems": 2,
      "contains": {"const": "foo"}
    }
    """
  )

  describe "array with minItems AND contains" do
    test "doesn't contain enough items" do
      assert {:error, _} = minitems_contains(["foo"])
    end

    test "dosn't contain the right item" do
      assert {:error, _} = minitems_contains(["bar", "baz"])
    end

    test "doesn't contain either the right item or enough items" do
      assert {:error, _} = minitems_contains(["bar"])
    end

    test "contains the right item and enough items" do
      assert :ok == minitems_contains(["foo", "bar"])
    end
  end

  describe "empty map only objects" do
    Exonerate.function_from_string(
      :def,
      :unevaluated_empty_map,
      ~S({"unevaluatedProperties": false})
    )

    test "unevaluated-empty ok" do
      assert :ok = unevaluated_empty_map(%{})
    end

    test "unevaluated-nonempty not ok" do
      assert {:error, _} = unevaluated_empty_map(%{"foo" => "bar"})
    end

    Exonerate.function_from_string(
      :def,
      :additional_empty_map,
      ~S({"additionalProperties": false})
    )

    test "additional-empty ok" do
      assert :ok = additional_empty_map(%{})
    end

    test "additional-nonempty not ok" do
      assert {:error, _} = additional_empty_map(%{"foo" => "bar"})
    end
  end

  describe "tracked object with iterator not needed" do
    Exonerate.function_from_string(
      :def,
      :tracked_internal,
      """
      {
        "allOf": [{"maxProperties": 3}],
        "unevaluatedProperties": {"type": "string"}
      }
      """
    )

    test "internal tracked object works" do
      assert :ok = tracked_internal(%{"foo" => "bar"})
      assert {:error, _} = tracked_internal(%{"foo" => 42})
    end

    Exonerate.function_from_string(
      :def,
      :tracked_nested,
      """
      {
        "allOf": [{
          "allOf": [{
            "maxProperties": 3
          }]
        }],
        "unevaluatedProperties": {"type": "string"}
      }
      """
    )

    test "nested tracked object works" do
      assert :ok = tracked_nested(%{"foo" => "bar"})
      assert {:error, _} = tracked_nested(%{"foo" => 3})
    end

    Exonerate.function_from_string(
      :def,
      :nested_not,
      """
      {
        "allOf": [{
          "not": {
            "maxProperties": 1
          }
        }],
        "unevaluatedProperties": {"type": "string"}
      }
      """
    )

    test "nested not works" do
      assert :ok = nested_not(%{"foo" => "bar", "baz" => "quux"})
      assert {:error, _} = nested_not(%{"foo" => "bar"})
      assert {:error, _} = nested_not(%{"foo" => "bar", "baz" => 42})
    end
  end

  describe "find iterators in filter contexts" do
    Exonerate.function_from_string(
      :def,
      :minitems_filter,
      """
      {
        "type": "array",
        "minItems": 2,
        "items": {
          "type": "string"
        }
      }
      """
    )

    test "minitems with items (obj)" do
      assert :ok = minitems_filter(~w(foo bar baz))
      assert {:error, list} = minitems_filter(["foo"])
      assert "#/minItems" == list[:absolute_keyword_location]

      assert {:error, list} = minitems_filter(["foo", "bar", 3])
      assert "#/items/type" == list[:absolute_keyword_location]
    end

    # NB items and prefixitems are already tested with additionalItems

    Exonerate.function_from_string(
      :def,
      :mincontains_filter,
      """
      {
        "type": "array",
        "contains": {"const": "foo"},
        "minContains": 2,
        "items": {
          "type": "string"
        }
      }
      """
    )

    test "mincontains with items (obj)" do
      assert :ok = mincontains_filter(~w(foo foo baz))
      assert {:error, list} = mincontains_filter(~w(foo bar baz))
      assert "#/minContains" == list[:absolute_keyword_location]

      assert {:error, list} = mincontains_filter(["foo", "foo", 3])
      assert "#/items/type" == list[:absolute_keyword_location]
    end
  end
end
