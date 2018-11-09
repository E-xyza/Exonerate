defmodule ExonerateCodesynthStringTest do
  use ExUnit.Case, async: true
  import ExonerateTest.Helper


  @tag :exonerate_codesynth
  test "unqualified string matching code" do
    codesynth_match(%{"type" => "string"}, """
      def validate_test(val) when is_binary(val), do: :ok
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "string matching code with length checking" do
    codesynth_match(%{"type" => "string", "minLength" => 3, "maxLength" => 5}, """
      def validate_test(val) when is_binary(val), do: [Exonerate.Checkers.check_minlength(val, 3), Exonerate.Checkers.check_maxlength(val, 5)] |> Exonerate.error_reduction()
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "string matching code with pattern matching" do
    codesynth_match(%{"type" => "string", "pattern" => "test"}, """
      @pattern_test Regex.compile("test") |> elem(1)

      def validate_test(val) when is_binary(val), do: Exonerate.Checkers.check_regex(@pattern_test, val)
      def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "string matching code with pattern, length, and format tests" do
    codesynth_match(
      %{"type" => "string", "minLength" => 3, "pattern" => "test", "format" => "uri"},
      """
        @pattern_test Regex.compile("test") |> elem(1)

        def validate_test(val) when is_binary(val), do: [Exonerate.Checkers.check_regex(@pattern_test, val), Exonerate.Checkers.check_format_uri(val), Exonerate.Checkers.check_minlength(val, 3)] |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{Jason.encode! val} does not conform to JSON schema\"}
      """
    )
  end
end
