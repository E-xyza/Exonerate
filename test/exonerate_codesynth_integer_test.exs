defmodule ExonerateCodesynthIntegerTest do
  use ExUnit.Case, async: true
  import ExonerateTest.Helper

  @moduledoc """
    some basic tests to ensure that code generated for integers looks sane.
  """

  @tag :exonerate_codesynth
  test "integer json schema with no restrictions" do
    codesynth_match(%{"type" => "integer"}, """
      def validate_test(val) when is_integer(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "integer json schema with mulitipleof restrictions" do
    codesynth_match(%{"type" => "integer", "multipleOf" => 3}, """
      def validate_test(val) when is_integer(val) and (rem(val,3) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_integer(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "integer json schema with mulitipleof and minimum restrictions" do
    codesynth_match(%{"type" => "integer", "multipleOf" => 3, "minimum" => 3}, """
      def validate_test(val) when is_integer(val) and (rem(val,3) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_integer(val) and (val < 3), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_integer(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "integer json schema with minimum and maximum restrictions" do
    codesynth_match(%{"type" => "integer", "minimum" => 3, "maximum" => 7}, """
      def validate_test(val) when is_integer(val) and (val < 3), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_integer(val) and (val > 7), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_integer(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "integer json schema with exclusive minimum restriction" do
    codesynth_match(
      %{"type" => "integer", "minimum" => 3, "exclusiveMinimum" => true, "maximum" => 7},
      """
        def validate_test(val) when is_integer(val) and (val <= 3), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
        def validate_test(val) when is_integer(val) and (val > 7), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
        def validate_test(val) when is_integer(val), do: :ok
        def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      """
    )
  end
end
