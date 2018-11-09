

defmodule ExonerateCodesynthArrayTest do
  use ExUnit.Case
  import ExonerateTest.Helper

  @moduledoc """
    some basic tests to ensure that code generated for arrays looks sane.
  """

  @tag :exonerate_codesynth
  test "basic array validation works" do
    codesynth_match(%{"type" => "array"}, """
      def validate_test(val) when is_list(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "arrays can validate with item specification" do
    codesynth_match(%{"type" => "array", "items" => %{"type" => "string"}}, """
      def validate_test__forall(val) when is_binary(val), do: :ok
      def validate_test__forall(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

      def validate_test(val) when is_list(val), do: Enum.map(val, &__MODULE__.validate_test__forall/1) |> Exonerate.error_reduction
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "arrays can validate with indexed item specification" do
    codesynth_match(
      %{"type" => "array", "items" => [%{"type" => "string"}, %{"type" => "integer"}]},
      """
        def validate_test_0(val) when is_binary(val), do: :ok
        def validate_test_0(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

        def validate_test_1(val) when is_integer(val), do: :ok
        def validate_test_1(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

        def validate_test__all(val) do
          val |> Enum.zip([&__MODULE__.validate_test_0/1, &__MODULE__.validate_test_1/1])
              |> Enum.map(fn {a, f} -> f.(a) end)
              |> Exonerate.error_reduction
        end

        def validate_test(val) when is_list(val), do: validate_test__all(val)
        def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "arrays can validate with minimum item count specification" do
    codesynth_match(%{"type" => "array", "minItems" => 3}, """
      def validate_test(val) when is_list(val) and length(val) < 3, do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_list(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "arrays can validate with maximum item count specification" do
    codesynth_match(%{"type" => "array", "maxItems" => 7}, """
      def validate_test(val) when is_list(val) and length(val) > 7, do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
      def validate_test(val) when is_list(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "arrays can validate with uniqueitem specification" do
    codesynth_match(%{"type" => "array", "uniqueItems" => true}, """
      def validate_test(val) when is_list(val), do: Exonerate.Checkers.check_unique(val)
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "arrays can validate with additional items specification" do
    codesynth_match(
      %{
        "type" => "array",
        "items" => [%{"type" => "string"}, %{"type" => "integer"}],
        "additionalItems" => false
      },
      """
        def validate_test_0(val) when is_binary(val), do: :ok
        def validate_test_0(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

        def validate_test_1(val) when is_integer(val), do: :ok
        def validate_test_1(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

        def validate_test__all(val) do
          val |> Enum.zip([&__MODULE__.validate_test_0/1, &__MODULE__.validate_test_1/1])
              |> Enum.map(fn {a, f} -> f.(a) end)
              |> Exonerate.error_reduction
        end

        def validate_test(val) when is_list(val) and (length(val) > 2), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
        def validate_test(val) when is_list(val), do: validate_test__all(val)
        def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
      """
    )
  end
end
