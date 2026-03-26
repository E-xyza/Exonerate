defmodule ExonerateTest.DecimalTest do
  use ExUnit.Case, async: true
  require Exonerate

  describe "decimal: :all with number type" do
    Exonerate.function_from_string(
      :defp,
      :number_min_max,
      """
      {"type": "number", "minimum": 0.1, "maximum": 99.9}
      """,
      decimal: :all
    )

    test "validates minimum with decimal arithmetic" do
      assert :ok = number_min_max(0.1)
      assert :ok = number_min_max(50)
      assert :ok = number_min_max(99.9)
      assert {:error, _} = number_min_max(0.05)
      assert {:error, _} = number_min_max(100)
    end

    Exonerate.function_from_string(
      :defp,
      :number_exclusive,
      """
      {"type": "number", "exclusiveMinimum": 0, "exclusiveMaximum": 100}
      """,
      decimal: :all
    )

    test "validates exclusive min/max with decimal arithmetic" do
      assert :ok = number_exclusive(0.001)
      assert :ok = number_exclusive(99.999)
      assert {:error, _} = number_exclusive(0)
      assert {:error, _} = number_exclusive(100)
    end
  end

  describe "decimal: :all with integer type" do
    Exonerate.function_from_string(
      :defp,
      :integer_min_max,
      """
      {"type": "integer", "minimum": 1, "maximum": 100}
      """,
      decimal: :all
    )

    test "validates integer min/max with decimal arithmetic" do
      assert :ok = integer_min_max(1)
      assert :ok = integer_min_max(50)
      assert :ok = integer_min_max(100)
      assert {:error, _} = integer_min_max(0)
      assert {:error, _} = integer_min_max(101)
    end

    Exonerate.function_from_string(
      :defp,
      :integer_multiple_of,
      """
      {"type": "integer", "multipleOf": 5}
      """,
      decimal: :all
    )

    test "validates multipleOf with decimal arithmetic" do
      assert :ok = integer_multiple_of(0)
      assert :ok = integer_multiple_of(5)
      assert :ok = integer_multiple_of(100)
      assert {:error, _} = integer_multiple_of(3)
      assert {:error, _} = integer_multiple_of(7)
    end
  end

  # NOTE: String type with decimal mode requires additional architectural work
  # since the String type module doesn't include numeric filters (min/max/multipleOf).
  # This could be added in a follow-up.

  describe "decimal: [at: [...]] path-based" do
    Exonerate.function_from_string(
      :defp,
      :path_based,
      """
      {
        "type": "object",
        "properties": {
          "price": {"type": "number", "minimum": 0.01, "maximum": 1000},
          "quantity": {"type": "integer", "minimum": 1}
        }
      }
      """,
      decimal: [at: ["/properties/price"]]
    )

    test "uses decimal at specified path" do
      assert :ok = path_based(%{"price" => 0.01, "quantity" => 1})
      assert :ok = path_based(%{"price" => 500.50, "quantity" => 100})
      assert {:error, _} = path_based(%{"price" => 0.001, "quantity" => 1})
    end

    test "uses standard arithmetic at non-decimal paths" do
      assert :ok = path_based(%{"price" => 1, "quantity" => 1})
      assert {:error, _} = path_based(%{"price" => 1, "quantity" => 0})
    end
  end

  describe "decimal with multipleOf for precise calculations" do
    Exonerate.function_from_string(
      :defp,
      :decimal_multiple_of,
      """
      {"type": "number", "multipleOf": 0.01}
      """,
      decimal: :all
    )

    test "validates decimal multipleOf precisely" do
      assert :ok = decimal_multiple_of(1.00)
      assert :ok = decimal_multiple_of(0.01)
      assert :ok = decimal_multiple_of(99.99)
      # This would fail with float arithmetic due to precision issues
      assert :ok = decimal_multiple_of(0.10)
    end
  end
end
